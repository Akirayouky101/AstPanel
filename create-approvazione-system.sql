-- ═══════════════════════════════════════════════════════════════════
-- Sistema Approvazione Ordini Interni con Link Magico
-- Eseguire in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Tabella impostazioni applicazione ─────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
    key        TEXT PRIMARY KEY,
    value      TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Valore di default
INSERT INTO app_settings (key, value)
VALUES ('email_approvazione', '')
ON CONFLICT (key) DO NOTHING;

-- RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Auth read app_settings"  ON app_settings;
DROP POLICY IF EXISTS "Auth write app_settings" ON app_settings;
CREATE POLICY "Auth read app_settings"  ON app_settings FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Auth write app_settings" ON app_settings FOR ALL    USING (auth.role() = 'authenticated');

-- ── 2. Tabella token di approvazione ─────────────────────────────
CREATE TABLE IF NOT EXISTS ordini_approvazione_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ordine_id  UUID NOT NULL REFERENCES ordini_interni(id) ON DELETE CASCADE,
    token      TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    used       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days'
);

-- RLS
ALTER TABLE ordini_approvazione_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anon read token"   ON ordini_approvazione_tokens;
DROP POLICY IF EXISTS "Auth insert token" ON ordini_approvazione_tokens;
CREATE POLICY "Anon read token"   ON ordini_approvazione_tokens FOR SELECT USING (true);
CREATE POLICY "Auth insert token" ON ordini_approvazione_tokens FOR INSERT WITH CHECK (true);

-- ── 3. RPC: leggi ordine da token (preview senza azione) ─────────
CREATE OR REPLACE FUNCTION get_ordine_by_token(p_token TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_token  ordini_approvazione_tokens%ROWTYPE;
    v_ordine ordini_interni%ROWTYPE;
BEGIN
    SELECT * INTO v_token FROM ordini_approvazione_tokens WHERE token = p_token;
    IF NOT FOUND         THEN RETURN json_build_object('ok', false, 'err', 'Link non valido.'); END IF;
    IF v_token.used      THEN RETURN json_build_object('ok', false, 'err', 'Link già utilizzato.'); END IF;
    IF v_token.expires_at < NOW() THEN RETURN json_build_object('ok', false, 'err', 'Link scaduto.'); END IF;

    SELECT * INTO v_ordine FROM ordini_interni WHERE id = v_token.ordine_id;
    IF NOT FOUND THEN RETURN json_build_object('ok', false, 'err', 'Ordine non trovato.'); END IF;

    RETURN json_build_object(
        'ok',          true,
        'numero',      v_ordine.numero,
        'oggetto',     v_ordine.oggetto,
        'fornitore',   v_ordine.fornitore_nome,
        'totale',      v_ordine.totale,
        'data_ordine', v_ordine.data_ordine::TEXT,
        'stato',       v_ordine.stato,
        'note',        v_ordine.note,
        'created_at',  v_ordine.created_at::TEXT
    );
END;
$$;

-- ── 4. RPC: esegui approvazione/rifiuto tramite token ────────────
CREATE OR REPLACE FUNCTION approva_ordine_con_token(p_token TEXT, p_azione TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_token  ordini_approvazione_tokens%ROWTYPE;
    v_ordine ordini_interni%ROWTYPE;
    v_stato  TEXT;
BEGIN
    SELECT * INTO v_token FROM ordini_approvazione_tokens WHERE token = p_token;
    IF NOT FOUND         THEN RETURN json_build_object('ok', false, 'err', 'Link non valido.'); END IF;
    IF v_token.used      THEN RETURN json_build_object('ok', false, 'err', 'Questo link è già stato utilizzato.'); END IF;
    IF v_token.expires_at < NOW() THEN RETURN json_build_object('ok', false, 'err', 'Link scaduto (validità 30 giorni).'); END IF;

    SELECT * INTO v_ordine FROM ordini_interni WHERE id = v_token.ordine_id;
    IF NOT FOUND THEN RETURN json_build_object('ok', false, 'err', 'Ordine non trovato.'); END IF;

    IF v_ordine.stato != 'in_attesa' THEN
        RETURN json_build_object(
            'ok', false,
            'err', 'Ordine non più in attesa di approvazione (stato attuale: ' || v_ordine.stato || ').'
        );
    END IF;

    v_stato := CASE WHEN p_azione = 'approva' THEN 'approvato' ELSE 'annullato' END;

    UPDATE ordini_interni
       SET stato = v_stato
     WHERE id = v_ordine.id;

    UPDATE ordini_approvazione_tokens
       SET used = true
     WHERE id = v_token.id;

    RETURN json_build_object(
        'ok',          true,
        'azione',      p_azione,
        'nuovo_stato', v_stato,
        'numero',      v_ordine.numero,
        'oggetto',     v_ordine.oggetto,
        'fornitore',   v_ordine.fornitore_nome,
        'totale',      v_ordine.totale
    );
END;
$$;

-- Grant execute to anon (for public approval page)
GRANT EXECUTE ON FUNCTION get_ordine_by_token(TEXT)           TO anon, authenticated;
GRANT EXECUTE ON FUNCTION approva_ordine_con_token(TEXT, TEXT) TO anon, authenticated;

-- ── 5. Abilita Supabase Realtime su ordini_interni ───────────────
-- Necessario perché le modifiche via RPC (approvazione) arrivino istantaneamente
-- al pannello admin senza refresh manuale.
ALTER TABLE ordini_interni REPLICA IDENTITY FULL;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE ordini_interni;
EXCEPTION WHEN duplicate_object THEN
    -- Tabella già presente nella pubblicazione, ignorare
    NULL;
END $$;

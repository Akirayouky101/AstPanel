-- ═══════════════════════════════════════════════════════════════════
-- Multi-Approvatori: ogni responsabile ha il proprio link personale
-- Eseguire in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Tabella approvatori ────────────────────────────────────────
-- Colonne mancanti su ordini_interni (se non già aggiunte)
ALTER TABLE ordini_interni ADD COLUMN IF NOT EXISTS approvato_tramite TEXT;

CREATE TABLE IF NOT EXISTS approvatori (
    id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    nome       TEXT        NOT NULL,
    email      TEXT        NOT NULL,
    token      TEXT        NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    attivo     BOOLEAN     DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Abilita RLS
ALTER TABLE approvatori ENABLE ROW LEVEL SECURITY;

-- Solo admin/authenticated possono gestire la tabella
DROP POLICY IF EXISTS "approvatori_admin_all" ON approvatori;
CREATE POLICY "approvatori_admin_all" ON approvatori
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Anon può leggere il proprio record tramite token (necessario per le RPC)
-- (accesso avviene solo via SECURITY DEFINER, non serve policy anon diretta)

-- ── 2. RPC: ottieni tutti gli ordini in attesa (token personale) ──
DROP FUNCTION IF EXISTS get_ordini_approvazione(TEXT);
CREATE OR REPLACE FUNCTION get_ordini_approvazione(p_token TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_approver RECORD;
BEGIN
    -- Valida token e recupera nome approvatore
    SELECT id, nome INTO v_approver
    FROM approvatori
    WHERE token = p_token AND attivo = true;

    IF NOT FOUND THEN
        -- Fallback: prova vecchio approver_session_token per compatibilità
        PERFORM 1 FROM app_settings
        WHERE key = 'approver_session_token' AND value = p_token;

        IF NOT FOUND THEN
            RETURN json_build_object('ok', false, 'err', 'Link non valido o scaduto.');
        END IF;

        -- Vecchio token: nome generico
        v_approver.nome := COALESCE(
            (SELECT NULLIF(TRIM(value),'') FROM app_settings WHERE key = 'approver_name'),
            'Responsabile'
        );
    END IF;

    RETURN (
        SELECT json_build_object(
            'ok',              true,
            'approvatore_nome', v_approver.nome,
            'ordini', COALESCE(json_agg(
                json_build_object(
                    'id',                    o.id,
                    'numero',                o.numero,
                    'tipo',                  o.tipo,
                    'oggetto',               o.oggetto,
                    'fornitore_nome',        o.fornitore_nome,
                    'data_ordine',           o.data_ordine::TEXT,
                    'data_consegna_prevista',o.data_consegna_prevista::TEXT,
                    'totale',                o.totale,
                    'subtotale',             o.subtotale,
                    'sconto_percentuale',    o.sconto_percentuale,
                    'iva_percentuale',       o.iva_percentuale,
                    'note',                  o.note,
                    'note_interne',          o.note_interne,
                    'chi_ha_ordinato',       o.chi_ha_ordinato,
                    'canale_ordine',         o.canale_ordine,
                    'created_at',            o.created_at::TEXT,
                    'items', (
                        SELECT COALESCE(json_agg(json_build_object(
                            'codice',            i.codice,
                            'nome',              COALESCE(c.nome, LEFT(i.descrizione, 80)),
                            'descrizione',       i.descrizione,
                            'quantita',          i.quantita,
                            'um',                i.um,
                            'prezzo_unitario',   i.prezzo_unitario,
                            'sconto_percentuale',i.sconto_percentuale,
                            'importo',           i.importo,
                            'note',              i.note
                        ) ORDER BY i.posizione), '[]'::json)
                        FROM ordini_interni_items i
                        LEFT JOIN components c ON c.id = i.prodotto_id
                        WHERE i.ordine_id = o.id
                    )
                ) ORDER BY o.created_at
            ), '[]'::json)
        )
        FROM ordini_interni o WHERE o.stato = 'in_attesa'
    );
END;
$$;

-- ── 3. RPC: approva/rifiuta tramite token personale ───────────────
DROP FUNCTION IF EXISTS approva_ordine_diretto(TEXT, UUID, TEXT);
CREATE OR REPLACE FUNCTION approva_ordine_diretto(p_token TEXT, p_ordine_id UUID, p_azione TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_approver      RECORD;
    v_approver_nome TEXT;
    v_ordine        ordini_interni%ROWTYPE;
    v_stato         TEXT;
BEGIN
    -- Valida token approvatore
    SELECT id, nome INTO v_approver
    FROM approvatori
    WHERE token = p_token AND attivo = true;

    IF NOT FOUND THEN
        -- Fallback vecchio session token
        PERFORM 1 FROM app_settings
        WHERE key = 'approver_session_token' AND value = p_token;

        IF NOT FOUND THEN
            RETURN json_build_object('ok', false, 'err', 'Accesso non autorizzato.');
        END IF;

        v_approver_nome := COALESCE(
            (SELECT NULLIF(TRIM(value),'') FROM app_settings WHERE key = 'approver_name'),
            'Responsabile'
        );
    ELSE
        v_approver_nome := v_approver.nome;
    END IF;

    -- Trova ordine
    SELECT * INTO v_ordine FROM ordini_interni WHERE id = p_ordine_id;
    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'err', 'Ordine non trovato.');
    END IF;

    IF v_ordine.stato != 'in_attesa' THEN
        RETURN json_build_object('ok', false, 'err',
            'Ordine non in attesa (stato attuale: ' || v_ordine.stato || ').');
    END IF;

    v_stato := CASE WHEN p_azione = 'approva' THEN 'approvato' ELSE 'annullato' END;

    UPDATE ordini_interni
    SET stato             = v_stato,
        approvato_da_nome = CASE WHEN p_azione = 'approva' THEN v_approver_nome ELSE NULL END,
        approvato_tramite = CASE WHEN p_azione = 'approva' THEN 'web' ELSE NULL END,
        data_approvazione = CASE WHEN p_azione = 'approva' THEN NOW() ELSE NULL END
    WHERE id = p_ordine_id;

    RETURN json_build_object(
        'ok',           true,
        'azione',       p_azione,
        'nuovo_stato',  v_stato,
        'numero',       v_ordine.numero,
        'approvato_da', CASE WHEN p_azione = 'approva' THEN v_approver_nome ELSE NULL END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION get_ordini_approvazione(TEXT)            TO anon, authenticated;
GRANT EXECUTE ON FUNCTION approva_ordine_diretto(TEXT, UUID, TEXT)  TO anon, authenticated;

-- ============================================================
-- AZIENDE: supporto multi-azienda per i preventivi
-- Ogni azienda ha i propri dati fiscali e numerazione separata
-- (es: "AST Impianti" → AST-2026-001, "VID Security" → VID-2026-001)
-- ============================================================

-- 1. TABELLA AZIENDE
CREATE TABLE IF NOT EXISTS aziende (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome             VARCHAR(200) NOT NULL,           -- nome breve, es: "AST"
    ragione_sociale  VARCHAR(300),                    -- es: "AST Impianti Srl"
    partita_iva      VARCHAR(30),
    codice_fiscale   VARCHAR(20),
    indirizzo        TEXT,
    cap              VARCHAR(10),
    citta            VARCHAR(100),
    provincia        VARCHAR(5),
    telefono         VARCHAR(50),
    email            VARCHAR(200),
    pec              VARCHAR(200),
    codice_sdi       VARCHAR(10),
    iban             VARCHAR(50),
    logo_url         TEXT,
    prefisso_numero  VARCHAR(20) DEFAULT 'PREV',      -- es: "AST", "VID", "ANT"
    prev_counter     INTEGER NOT NULL DEFAULT 0,      -- contatore anno corrente
    prev_anno        INTEGER NOT NULL DEFAULT EXTRACT(YEAR FROM NOW())::INTEGER,
    note             TEXT,
    attiva           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 2. AGGIUNGI azienda_id A preventivi
ALTER TABLE preventivi ADD COLUMN IF NOT EXISTS azienda_id UUID REFERENCES aziende(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_preventivi_azienda ON preventivi(azienda_id);

-- 3. RLS
ALTER TABLE aziende ENABLE ROW LEVEL SECURITY;

CREATE POLICY "aziende_select" ON aziende FOR SELECT USING (true);
CREATE POLICY "aziende_insert" ON aziende FOR INSERT WITH CHECK (true);
CREATE POLICY "aziende_update" ON aziende FOR UPDATE USING (true);
CREATE POLICY "aziende_delete" ON aziende FOR DELETE USING (true);

-- 4. FUNZIONE: genera numero preventivo per azienda specifica
--    Incremento atomico con reset automatico al cambio anno
CREATE OR REPLACE FUNCTION generate_preventivo_numero_azienda(p_azienda_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_anno     INTEGER := EXTRACT(YEAR FROM NOW())::INTEGER;
    v_counter  INTEGER;
    v_prefisso TEXT;
BEGIN
    -- Se anno cambiato, resetta il contatore
    UPDATE aziende
    SET prev_counter = 0,
        prev_anno    = v_anno
    WHERE id = p_azienda_id
      AND prev_anno < v_anno;

    -- Incremento atomico e ritorno contatore + prefisso
    UPDATE aziende
    SET prev_counter = prev_counter + 1,
        updated_at   = NOW()
    WHERE id = p_azienda_id
    RETURNING prev_counter, prefisso_numero
    INTO v_counter, v_prefisso;

    IF v_counter IS NULL THEN
        RAISE EXCEPTION 'Azienda % non trovata', p_azienda_id;
    END IF;

    RETURN v_prefisso || '-' || v_anno || '-' || LPAD(v_counter::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. GRANT
GRANT EXECUTE ON FUNCTION generate_preventivo_numero_azienda(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_preventivo_numero_azienda(UUID) TO anon;

DO $$ BEGIN RAISE NOTICE '✅ Tabella aziende creata, azienda_id aggiunto a preventivi, funzione generate_preventivo_numero_azienda registrata'; END $$;

-- =====================================================
-- Tabella storico azioni su richieste preventivo fornitori
-- Traccia: chi ha creato, modificato, richiesto approvazione,
-- approvato o rifiutato — con note automatiche sugli articoli
-- =====================================================

CREATE TABLE IF NOT EXISTS richieste_preventivo_storia (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    richiesta_id   UUID NOT NULL REFERENCES richieste_preventivo_fornitori(id) ON DELETE CASCADE,
    tipo           TEXT NOT NULL,      -- 'creazione' | 'modifica' | 'richiesta_modifica' | 'approvazione' | 'rifiuto' | 'presa_visione' | 'invio_email'
    autore_nome    TEXT,               -- nome cognome di chi ha eseguito l'azione
    autore_id      UUID,               -- user id (opzionale)
    note           TEXT,               -- es. "Eliminato Tubo 1/2; Aggiunto Cavo 2mt x3"
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice per query veloci per richiesta
CREATE INDEX IF NOT EXISTS idx_storia_richiesta_id ON richieste_preventivo_storia(richiesta_id, created_at DESC);

-- RLS
ALTER TABLE richieste_preventivo_storia ENABLE ROW LEVEL SECURITY;

-- Policy aperta ad autenticati (stesso pattern del resto del sistema)
DROP POLICY IF EXISTS "storia_allow_authenticated" ON richieste_preventivo_storia;
CREATE POLICY "storia_allow_authenticated"
    ON richieste_preventivo_storia
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Permesso anche ad anon per le pagine approvazione (token link)
GRANT SELECT, INSERT ON richieste_preventivo_storia TO anon, authenticated;

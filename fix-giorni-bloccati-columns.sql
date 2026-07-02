-- Aggiunge le colonne mancanti alla tabella giorni_bloccati
ALTER TABLE giorni_bloccati
    ADD COLUMN IF NOT EXISTS user_ids JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS motivo TEXT,
    ADD COLUMN IF NOT EXISTS colore VARCHAR(20) DEFAULT '#ef4444',
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Oppure, se la tabella non esiste affatto o vuoi ricrearla:
-- DROP TABLE IF EXISTS giorni_bloccati;
-- (poi esegui create-giorni-bloccati.sql)

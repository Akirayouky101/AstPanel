-- Aggiunge colonne ora_inizio e ora_fine alla tabella giorni_bloccati
-- per supportare blocchi parziali (non tutto il giorno)
ALTER TABLE giorni_bloccati
    ADD COLUMN IF NOT EXISTS ora_inizio TIME DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS ora_fine   TIME DEFAULT NULL;

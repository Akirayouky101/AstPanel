-- =====================================================
-- Aggiunge colonna visibile alle lavorazioni
-- visibile = TRUE  → visibile a tutti (default)
-- visibile = FALSE → solo admin, dipendenti non la vedono (STANDBY)
-- =====================================================

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS visibile BOOLEAN NOT NULL DEFAULT TRUE;

-- Tutte le lavorazioni esistenti rimangono visibili
UPDATE tasks SET visibile = TRUE WHERE visibile IS NULL;

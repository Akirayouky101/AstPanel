-- ============================================================
-- Aggiunge supporto multi-giornate alle lavorazioni (tasks)
-- ============================================================

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS giornate_json TEXT DEFAULT NULL;

DO $$ BEGIN
    RAISE NOTICE '✅ Colonna giornate_json aggiunta a tasks';
END $$;

-- ============================================================
-- MIGRAZIONE: Aggiunge referente commerciale alla tabella fornitori
-- ============================================================
-- Esegui nel Supabase SQL Editor
-- ============================================================

ALTER TABLE fornitori
    ADD COLUMN IF NOT EXISTS referente_commerciale VARCHAR(200),
    ADD COLUMN IF NOT EXISTS referente_email       VARCHAR(200),
    ADD COLUMN IF NOT EXISTS referente_telefono    VARCHAR(50);

DO $$ BEGIN
    RAISE NOTICE '✅ Colonna referente_commerciale aggiunta a fornitori';
    RAISE NOTICE '✅ Colonna referente_email aggiunta a fornitori';
    RAISE NOTICE 'ℹ️  referente_email è la mail usata per inviare gli ordini';
END $$;

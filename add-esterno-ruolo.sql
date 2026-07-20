-- =====================================================
-- MIGRAZIONE: Aggiunge il ruolo 'esterno' alla tabella users
-- Gli esterni sono persone non dipendenti che accompagnano
-- i tecnici durante le lavorazioni (nessun accesso al sistema)
-- =====================================================

-- 1. Aggiorna il CHECK constraint per includere 'esterno'
ALTER TABLE users 
    DROP CONSTRAINT IF EXISTS users_ruolo_check;

ALTER TABLE users 
    ADD CONSTRAINT users_ruolo_check 
    CHECK (ruolo IN ('admin', 'dipendente', 'tecnico', 'titolare', 'segreteria', 'esterno'));

-- 2. Verifica che l'aggiornamento sia andato a buon fine
SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint 
WHERE conrelid = 'users'::regclass AND contype = 'c' AND conname = 'users_ruolo_check';

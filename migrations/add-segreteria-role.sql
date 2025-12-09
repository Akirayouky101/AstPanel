-- =====================================================
-- AGGIUNGI RUOLI ITALIANI CORRETTI
-- =====================================================
-- Ruoli:
-- - Titolare (admin)
-- - Tecnico (admin)
-- - Segreteria (admin)
-- - Dipendente (utente)
-- =====================================================

-- Elimina il constraint esistente
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- Ricrea il constraint con i ruoli italiani
ALTER TABLE public.users 
ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('Titolare', 'Tecnico', 'Segreteria', 'Dipendente'));

-- Verifica
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'users_ruolo_check';

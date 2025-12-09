-- =====================================================
-- AGGIUNGI 'segreteria' AL CONSTRAINT ruolo
-- =====================================================
-- Per supportare il ruolo Segreteria richiesto dall'AI
-- =====================================================

-- Elimina il constraint esistente
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- Ricrea il constraint con 'segreteria' incluso
ALTER TABLE public.users 
ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('admin', 'dipendente', 'tecnico', 'segreteria'));

-- Verifica
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'users_ruolo_check';

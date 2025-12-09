-- =====================================================
-- FIX CONSTRAINT RUOLO
-- =====================================================
-- Rimuove vecchio constraint e ne crea uno nuovo
-- con valori corretti: admin, dipendente, tecnico
-- =====================================================

-- Step 1: Drop vecchio constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- Step 2: Crea nuovo constraint con valori corretti
ALTER TABLE users 
ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('admin', 'dipendente', 'tecnico'));

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ Constraint users_ruolo_check aggiornato';
    RAISE NOTICE '   Valori permessi: admin, dipendente, tecnico';
END $$;

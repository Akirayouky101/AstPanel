-- =====================================================
-- FIX CONSTRAINT RUOLO (PARTENDO DA ZERO)
-- =====================================================
-- Svuota tabella users e ricrea constraint corretto
-- Valori permessi: admin, dipendente, tecnico
-- =====================================================

-- Step 1: Elimina tutti gli utenti esistenti (reset completo)
TRUNCATE TABLE users CASCADE;

-- Step 2: Drop vecchio constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;

-- Step 3: Crea nuovo constraint con valori corretti
ALTER TABLE users 
ADD CONSTRAINT users_ruolo_check 
CHECK (ruolo IN ('admin', 'dipendente', 'tecnico'));

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ Tabella users svuotata e constraint aggiornato';
    RAISE NOTICE '   Valori permessi: admin, dipendente, tecnico';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prossimo passo:';
    RAISE NOTICE '   Vai su first-setup.html per creare primo admin';
END $$;

-- =====================================================
-- ROLLBACK SISTEMA GESTIONE MEZZI/FURGONI
-- =====================================================
-- Rimuove completamente tutto il sistema mezzi
-- =====================================================

-- 1. DROP TRIGGER (prima delle funzioni!)
DROP TRIGGER IF EXISTS vehicles_updated_at ON vehicles;
DROP TRIGGER IF EXISTS vehicle_assignments_updated_at ON vehicle_assignments;

-- 2. DROP FUNZIONI
DROP FUNCTION IF EXISTS get_vehicles_dashboard();
DROP FUNCTION IF EXISTS get_available_vehicles(DATE, DATE);
DROP FUNCTION IF EXISTS update_vehicles_updated_at();

-- 3. DROP POLICIES
DROP POLICY IF EXISTS "vehicle_assignments_delete_admin" ON vehicle_assignments;
DROP POLICY IF EXISTS "vehicle_assignments_update_own" ON vehicle_assignments;
DROP POLICY IF EXISTS "vehicle_assignments_insert_own" ON vehicle_assignments;
DROP POLICY IF EXISTS "vehicle_assignments_select_all" ON vehicle_assignments;

DROP POLICY IF EXISTS "vehicles_delete_admin" ON vehicles;
DROP POLICY IF EXISTS "vehicles_update_admin" ON vehicles;
DROP POLICY IF EXISTS "vehicles_insert_admin" ON vehicles;
DROP POLICY IF EXISTS "vehicles_select_all" ON vehicles;

-- 4. DROP INDICI
DROP INDEX IF EXISTS idx_vehicle_assignments_stato;
DROP INDEX IF EXISTS idx_vehicle_assignments_date;
DROP INDEX IF EXISTS idx_vehicle_assignments_user;
DROP INDEX IF EXISTS idx_vehicle_assignments_vehicle;
DROP INDEX IF EXISTS idx_vehicles_targa;
DROP INDEX IF EXISTS idx_vehicles_proprieta;
DROP INDEX IF EXISTS idx_vehicles_stato;

-- 5. DROP TABELLE (CASCADE rimuove anche le FK)
DROP TABLE IF EXISTS vehicle_assignments CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  ========================================';
    RAISE NOTICE '🗑️  SISTEMA MEZZI COMPLETAMENTE RIMOSSO';
    RAISE NOTICE '🗑️  ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tabelle rimosse:';
    RAISE NOTICE '  • vehicles';
    RAISE NOTICE '  • vehicle_assignments';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Funzioni rimosse:';
    RAISE NOTICE '  • get_available_vehicles()';
    RAISE NOTICE '  • get_vehicles_dashboard()';
    RAISE NOTICE '  • update_vehicles_updated_at()';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Indici e Policies rimossi';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Database tornato allo stato precedente';
    RAISE NOTICE '';
END $$;

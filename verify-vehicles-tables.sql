-- =====================================================
-- VERIFICA TABELLE VEHICLES
-- =====================================================

-- 1. Verifica esistenza tabella vehicles
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'vehicles'
) as vehicles_exists;

-- 2. Se esiste, conta record
SELECT COUNT(*) as total_vehicles FROM vehicles;

-- 3. Verifica esistenza tabella vehicle_assignments
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'vehicle_assignments'
) as vehicle_assignments_exists;

-- 4. Se esiste, conta record
SELECT COUNT(*) as total_assignments FROM vehicle_assignments;

-- 5. Lista tutte le tabelle nel database
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

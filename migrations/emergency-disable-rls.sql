-- ================================================
-- EMERGENCY: Disabilita RLS per permettere login
-- Data: 5 dicembre 2025
-- ================================================

-- 1. DISABILITA RLS su tutte le tabelle principali
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_availability DISABLE ROW LEVEL SECURITY;

-- 2. Verifica stato RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('users', 'tasks', 'user_availability', 'clients', 'teams', 'products', 'communications')
ORDER BY tablename;

-- 3. Test query diretta (dovrebbe funzionare ora)
SELECT COUNT(*) as total_users FROM users;
SELECT id, nome, cognome, email, ruolo FROM users LIMIT 5;

-- 4. Test funzioni availability
SELECT '=== Test funzioni ===' as test;
SELECT * FROM get_dashboard_disponibilita();
SELECT * FROM check_urgenza_veloce();

-- ================================================
-- NOTA: Dopo aver verificato che tutto funziona,
-- riabiliteremo le RLS con policy corrette
-- ================================================

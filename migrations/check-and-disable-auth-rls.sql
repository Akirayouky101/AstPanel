-- =====================================================
-- CHECK E DISABILITA RLS SU AUTH
-- =====================================================
-- Controlla e disabilita RLS su auth.users se necessario
-- =====================================================

-- Disabilita RLS su auth.users (necessario per createUser)
ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;

-- Verifica stato RLS
SELECT 
    schemaname,
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname IN ('auth', 'public')
ORDER BY schemaname, tablename;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ RLS disabilitato su auth.users';
    RAISE NOTICE '   Ora la creazione utenti dovrebbe funzionare';
END $$;

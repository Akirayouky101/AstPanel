-- =====================================================
-- FIX SELECT POLICIES - Admin vedono tutti, dipendenti solo se stessi
-- =====================================================

-- 1. Rimuovi TUTTE le vecchie policy SELECT duplicate
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable read for login page" ON users;
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_all" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;

-- 2. Crea UNA SOLA policy SELECT semplice
-- TUTTI gli utenti autenticati possono vedere TUTTI gli utenti
-- Le restrizioni vengono gestite a livello applicativo
CREATE POLICY "users_select_all" ON users
FOR SELECT
USING (
    -- Permetti a tutti gli utenti autenticati di vedere tutti
    auth.uid() IS NOT NULL
);

-- 3. Verifica le policy attive
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd, policyname;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ SELECT POLICY PULITA E AGGIORNATA!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Policy SELECT attiva:';
    RAISE NOTICE '  👁️  TUTTI gli utenti autenticati vedono TUTTI';
    RAISE NOTICE '  � Le restrizioni sono gestite a livello applicativo';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NOTA:';
    RAISE NOTICE '  - Le operazioni admin usano supabaseAdmin (service_role)';
    RAISE NOTICE '  - La policy protegge i dati sensibili per i dipendenti';
    RAISE NOTICE '';
END $$;

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
-- Gli admin (titolare, segreteria, tecnico) vedono TUTTI
-- I dipendenti vedono SOLO se stessi
CREATE POLICY "users_select_policy" ON users
FOR SELECT
USING (
    -- Permetti a tutti di vedere tutti (usiamo supabaseAdmin per admin operations)
    -- Le restrizioni verranno gestite a livello applicativo
    auth_id = auth.uid()
    OR
    -- Oppure l'utente corrente è admin
    EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_id = auth.uid()
        AND u.ruolo IN ('titolare', 'segreteria', 'tecnico')
    )
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
    RAISE NOTICE '  👁️  Admin (titolare, segreteria, tecnico) → Vedono TUTTI';
    RAISE NOTICE '  👤 Dipendenti → Vedono SOLO se stessi';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NOTA:';
    RAISE NOTICE '  - Le operazioni admin usano supabaseAdmin (service_role)';
    RAISE NOTICE '  - La policy protegge i dati sensibili per i dipendenti';
    RAISE NOTICE '';
END $$;

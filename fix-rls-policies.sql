-- =====================================================
-- FIX RLS POLICIES - Usa auth_id invece di auth.uid()
-- =====================================================
-- Le policy devono usare il campo auth_id per collegare correttamente
-- gli utenti Supabase Auth con la tabella users
-- =====================================================

-- 1. Elimina le vecchie policy
DROP POLICY IF EXISTS admin_all ON users;
DROP POLICY IF EXISTS user_own_data ON users;

-- 2. Crea nuove policy corrette

-- Policy per tutti gli utenti autenticati: possono leggere il proprio record
CREATE POLICY users_select_own ON users 
FOR SELECT 
USING (auth_id = auth.uid());

-- Policy per tutti gli utenti autenticati: possono aggiornare il proprio record
CREATE POLICY users_update_own ON users 
FOR UPDATE 
USING (auth_id = auth.uid());

-- Policy per SERVICE ROLE: accesso completo (per operazioni admin)
CREATE POLICY users_service_role_all ON users 
FOR ALL 
USING (auth.jwt() ->> 'role' = 'service_role');

-- 3. Verifica policy attive
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- =====================================================
-- Messaggio di conferma
-- =====================================================
DO $$ 
BEGIN 
    RAISE NOTICE '✅ RLS Policies aggiornate correttamente!';
    RAISE NOTICE '📋 Ora la query .eq(auth_id, session.user.id) funzionerà correttamente';
END $$;

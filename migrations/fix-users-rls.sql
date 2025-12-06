-- ================================================
-- FIX: RLS policies per users
-- Data: 6 dicembre 2025
-- Descrizione: Permette agli utenti autenticati di leggere la lista users
-- ================================================

-- 1. Visualizza le policy esistenti
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'users';

-- 2. Verifica se RLS è abilitato
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- 3. Abilita RLS se non è già abilitato
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 4. Rimuovi policy esistenti che potrebbero dare conflitto
DROP POLICY IF EXISTS "Enable read for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "users_delete_policy" ON users;

-- 5. Crea nuove policy PERMISSIVE per authenticated
CREATE POLICY "users_select_policy" ON users
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "users_insert_policy" ON users
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "users_update_policy" ON users
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "users_delete_policy" ON users
FOR DELETE TO authenticated
USING (true);

-- 6. Verifica le nuove policy
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'users';

SELECT '✅ RLS policies per users configurate correttamente!' as status;

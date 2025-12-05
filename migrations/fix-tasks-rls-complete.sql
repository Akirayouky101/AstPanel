-- ================================================
-- FIX COMPLETO: RLS policies per tasks
-- ================================================

-- Step 1: Visualizza le policy esistenti
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'tasks';

-- Step 2: Rimuovi TUTTE le policy esistenti
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable read for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable insert for all users" ON tasks;
DROP POLICY IF EXISTS "Enable read access for all users" ON tasks;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON tasks;

-- Step 3: Verifica se RLS è abilitato (deve essere true)
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'tasks' AND schemaname = 'public';

-- Step 4: Se RLS non è abilitato, abilitalo
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Step 5: Crea nuove policy PERMISSIVE per authenticated
CREATE POLICY "tasks_insert_policy" ON tasks
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "tasks_select_policy" ON tasks
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "tasks_update_policy" ON tasks
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "tasks_delete_policy" ON tasks
FOR DELETE TO authenticated
USING (true);

-- Step 6: Verifica le nuove policy
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'tasks';

SELECT '✅ RLS policies per tasks configurate correttamente!' as status;

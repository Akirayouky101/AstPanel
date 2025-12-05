-- ================================================
-- FIX: Aggiungi RLS policy per INSERT tasks
-- ================================================

-- Permetti agli utenti autenticati di creare tasks
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON tasks;
CREATE POLICY "Enable insert for authenticated users" ON tasks
FOR INSERT TO authenticated
WITH CHECK (true);

-- Permetti agli utenti autenticati di aggiornare tasks
DROP POLICY IF EXISTS "Enable update for authenticated users" ON tasks;
CREATE POLICY "Enable update for authenticated users" ON tasks
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

-- Permetti agli utenti autenticati di leggere tasks
DROP POLICY IF EXISTS "Enable read for authenticated users" ON tasks;
CREATE POLICY "Enable read for authenticated users" ON tasks
FOR SELECT TO authenticated
USING (true);

-- Permetti agli utenti autenticati di eliminare tasks
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON tasks;
CREATE POLICY "Enable delete for authenticated users" ON tasks
FOR DELETE TO authenticated
USING (true);

SELECT '✅ RLS policies per tasks configurate' as status;

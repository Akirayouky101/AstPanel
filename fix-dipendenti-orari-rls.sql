-- =====================================================
-- FIX RLS: Permetti ai dipendenti di aggiornare orari sui task assegnati
-- =====================================================
-- Eseguire nel SQL editor di Supabase
-- =====================================================

-- 1. Rimuovi policy UPDATE esistenti su tasks (potrebbero essere troppo restrittive)
DROP POLICY IF EXISTS tasks_update_policy ON tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON tasks;
DROP POLICY IF EXISTS admin_all ON tasks;
DROP POLICY IF EXISTS "admin_all" ON tasks;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON tasks;

-- 2. Assicurati che RLS sia abilitato
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- 3. Policy UPDATE: TUTTI gli utenti autenticati possono aggiornare i task
--    (admin gestiscono tutti i campi, dipendenti aggiornano i propri orari)
CREATE POLICY "tasks_update_policy" ON tasks
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Assicurati che anche le policy SELECT/INSERT/DELETE esistano
DROP POLICY IF EXISTS "tasks_select_policy" ON tasks;
CREATE POLICY "tasks_select_policy" ON tasks
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "tasks_insert_policy" ON tasks;
CREATE POLICY "tasks_insert_policy" ON tasks
FOR INSERT TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "tasks_delete_policy" ON tasks;
CREATE POLICY "tasks_delete_policy" ON tasks
FOR DELETE TO authenticated
USING (true);

-- 5. Verifica le policy attive su tasks
SELECT 
    policyname,
    cmd as operazione,
    permissive,
    roles
FROM pg_policies
WHERE tablename = 'tasks'
ORDER BY cmd;

DO $$ 
BEGIN 
    RAISE NOTICE '✅ RLS policies per tasks aggiornate!';
    RAISE NOTICE '   I dipendenti possono ora salvare ora_inizio e ora_fine';
END $$;

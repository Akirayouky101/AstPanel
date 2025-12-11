-- Verifica se RLS è attivo sulle tabelle

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'tasks', 'task_assignments')
ORDER BY tablename;

-- Se RLS è attivo, vedi le policies
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
WHERE schemaname = 'public'
    AND tablename IN ('users', 'tasks', 'task_assignments')
ORDER BY tablename, policyname;

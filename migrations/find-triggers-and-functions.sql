-- =====================================================
-- TROVA TRIGGER E FUNZIONI CHE BLOCCANO AUTH
-- =====================================================

-- 1. Lista tutti i trigger nel database
SELECT 
    trigger_schema,
    trigger_name,
    event_object_schema,
    event_object_table,
    action_statement,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE event_object_schema IN ('auth', 'public')
ORDER BY trigger_schema, trigger_name;

-- 2. Lista tutte le funzioni custom
SELECT 
    routine_schema,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines
WHERE routine_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY routine_schema, routine_name;

-- 3. Controlla se ci sono policy RLS attive
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
WHERE schemaname IN ('auth', 'public')
ORDER BY schemaname, tablename, policyname;

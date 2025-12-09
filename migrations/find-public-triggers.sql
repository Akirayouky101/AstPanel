-- =====================================================
-- TROVA TRIGGER SU TABELLE PUBLIC
-- =====================================================

-- Lista trigger su tabelle public che potrebbero interferire
SELECT 
    schemaname,
    tablename,
    COUNT(*) as num_triggers
FROM pg_tables t
LEFT JOIN pg_trigger tr ON tr.tgrelid = (schemaname || '.' || tablename)::regclass
WHERE schemaname = 'public'
  AND tr.tgisinternal = false
GROUP BY schemaname, tablename
HAVING COUNT(*) > 0;

-- Lista funzioni custom che potrebbero essere trigger
SELECT 
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    CASE 
        WHEN p.prorettype = 'trigger'::regtype THEN 'TRIGGER FUNCTION'
        ELSE pg_get_function_result(p.oid)
    END as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND (p.prorettype = 'trigger'::regtype OR p.proname LIKE '%trigger%')
ORDER BY p.proname;

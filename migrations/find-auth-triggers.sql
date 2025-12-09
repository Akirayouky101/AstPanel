-- =====================================================
-- TROVA E DISABILITA TRIGGER SU AUTH.USERS
-- =====================================================

-- 1. Lista trigger su auth.users
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    proname as function_name,
    pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'auth.users'::regclass
  AND tgisinternal = false;

-- 2. Mostra definizione funzioni trigger
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'auth.users'::regclass
  AND tgisinternal = false;

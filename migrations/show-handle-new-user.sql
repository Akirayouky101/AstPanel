-- =====================================================
-- MOSTRA DEFINIZIONE handle_new_user
-- =====================================================

-- Mostra la definizione completa della funzione
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- Mostra dove è usata (su quale tabella e quale evento)
SELECT 
    t.tgname as trigger_name,
    c.relname as table_name,
    n.nspname as schema_name,
    t.tgenabled as enabled,
    CASE t.tgtype::int & 66
        WHEN 2 THEN 'BEFORE'
        WHEN 64 THEN 'INSTEAD OF'
        ELSE 'AFTER'
    END as trigger_timing,
    CASE t.tgtype::int & 28
        WHEN 4 THEN 'INSERT'
        WHEN 8 THEN 'DELETE'
        WHEN 16 THEN 'UPDATE'
        WHEN 12 THEN 'INSERT OR DELETE'
        WHEN 20 THEN 'INSERT OR UPDATE'
        WHEN 24 THEN 'UPDATE OR DELETE'
        WHEN 28 THEN 'INSERT OR UPDATE OR DELETE'
    END as trigger_event
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE p.proname = 'handle_new_user';

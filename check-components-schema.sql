-- 🔍 VERIFICA SCHEMA TABELLA COMPONENTS
-- Esegui su Supabase per vedere i tipi di dato

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'components'
ORDER BY ordinal_position;

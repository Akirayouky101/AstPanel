-- Mostra la struttura completa di ordini_fornitore
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'ordini_fornitore' 
AND table_schema = 'public'
ORDER BY ordinal_position;

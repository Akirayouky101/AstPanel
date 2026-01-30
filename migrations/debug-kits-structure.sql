-- Mostra solo la struttura della tabella kits
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'kits' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verifica quale tabella ha i prodotti e i fornitori
SELECT 'PRODOTTI' as tabella, column_name 
FROM information_schema.columns 
WHERE table_name = 'prodotti' 
AND table_schema = 'public'
AND column_name LIKE '%fornit%'
ORDER BY ordinal_position;

-- Verifica components
SELECT 'COMPONENTS' as tabella, column_name 
FROM information_schema.columns 
WHERE table_name = 'components' 
AND table_schema = 'public'
AND column_name LIKE '%fornit%'
ORDER BY ordinal_position;

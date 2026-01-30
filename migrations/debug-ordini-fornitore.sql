-- ============================================
-- DEBUG ORDINI FORNITORE
-- ============================================

-- 1. Verifica se le tabelle esistono
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('ordini_fornitore', 'ordini_fornitore_items')
ORDER BY table_name;

-- 2. Se esiste, mostra la struttura di ordini_fornitore
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'ordini_fornitore' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Se esiste, mostra la struttura di ordini_fornitore_items
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'ordini_fornitore_items' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Mostra ordini esistenti (se ci sono)
SELECT * FROM ordini_fornitore ORDER BY created_at DESC LIMIT 5;

-- ============================================
-- FINE DEBUG
-- ============================================

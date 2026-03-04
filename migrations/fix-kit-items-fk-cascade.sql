-- =====================================================
-- FIX: kit_items.prodotto_id FK da RESTRICT a CASCADE
-- =====================================================
-- La FK RESTRICT impedisce l'eliminazione di components
-- anche quando kit_items vengono eliminati prima via RLS.
-- Cambiamo a SET NULL per permettere il delete di components
-- mantenendo lo storico dei kit.
-- =====================================================

-- 1. Rimuovi il vecchio constraint RESTRICT
ALTER TABLE kit_items
DROP CONSTRAINT IF EXISTS kit_items_prodotto_id_fkey;

-- 2. Ricrea con SET NULL (mantiene lo storico, non blocca il delete)
ALTER TABLE kit_items
ADD CONSTRAINT kit_items_prodotto_id_fkey
FOREIGN KEY (prodotto_id)
REFERENCES components(id)
ON DELETE SET NULL;

-- Nota: prodotto_id era NOT NULL, dobbiamo renderlo nullable
ALTER TABLE kit_items
ALTER COLUMN prodotto_id DROP NOT NULL;

SELECT '✅ FK kit_items.prodotto_id cambiata da RESTRICT a SET NULL' AS status;

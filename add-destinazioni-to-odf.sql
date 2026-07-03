-- =====================================================
-- Aggiunge supporto destinazioni (set di consegna)
-- agli ordini fornitore, copiato dalla richiesta preventivo
-- =====================================================

-- 1. Colonna destinazioni JSONB sull'ordine
ALTER TABLE ordini_fornitore
  ADD COLUMN IF NOT EXISTS destinazioni JSONB DEFAULT NULL;

-- 2. Colonna destinazione_id sugli item (stesso UUID usato nella richiesta)
ALTER TABLE ordini_fornitore_items
  ADD COLUMN IF NOT EXISTS destinazione_id TEXT DEFAULT NULL;

-- Verifica
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('ordini_fornitore', 'ordini_fornitore_items')
  AND column_name IN ('destinazioni', 'destinazione_id')
ORDER BY table_name, column_name;

-- ============================================================
-- CONVERTI PREVENTIVO → ORDINE FORNITORE
-- Aggiunge i campi di collegamento tra le due tabelle
-- ESEGUIRE nel Supabase SQL Editor
-- ============================================================

-- 1. Aggiunge richiesta_id a ordini_fornitore
--    (collega l'ordine alla richiesta preventivo di origine)
ALTER TABLE ordini_fornitore
ADD COLUMN IF NOT EXISTS richiesta_id UUID REFERENCES richieste_preventivo_fornitori(id) ON DELETE SET NULL;

-- 2. Aggiunge ordine_fornitore_id a richieste_preventivo_fornitori
--    (permette di sapere se la richiesta è già stata convertita in ordine)
ALTER TABLE richieste_preventivo_fornitori
ADD COLUMN IF NOT EXISTS ordine_fornitore_id UUID REFERENCES ordini_fornitore(id) ON DELETE SET NULL;

-- 3. Indice per query veloci
CREATE INDEX IF NOT EXISTS idx_ordini_fornitore_richiesta_id
    ON ordini_fornitore(richiesta_id);

CREATE INDEX IF NOT EXISTS idx_richieste_preventivo_ordine_id
    ON richieste_preventivo_fornitori(ordine_fornitore_id);

-- Verifica
SELECT
    column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('ordini_fornitore', 'richieste_preventivo_fornitori')
  AND column_name IN ('richiesta_id', 'ordine_fornitore_id')
ORDER BY table_name, column_name;

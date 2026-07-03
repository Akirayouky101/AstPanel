-- =====================================================
-- Aggiunge ordine_interno_id a ordini_fornitore
-- per tracciare da quale ordine interno è nato l'ODF
-- =====================================================

ALTER TABLE ordini_fornitore
  ADD COLUMN IF NOT EXISTS ordine_interno_id UUID REFERENCES ordini_interni(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ordini_fornitore_ordine_interno
  ON ordini_fornitore(ordine_interno_id);

-- Verifica
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ordini_fornitore'
  AND column_name = 'ordine_interno_id';

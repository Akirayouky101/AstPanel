-- ============================================
-- AGGIUNTA FORNITORE AI PRODOTTI
-- ============================================
-- Permette di associare un fornitore predefinito
-- ad ogni prodotto/componente
-- ============================================

-- 1. Aggiungi campo fornitore_id a components
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS fornitore_id UUID REFERENCES fornitori(id) ON DELETE SET NULL;

-- 2. Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_components_fornitore ON components(fornitore_id);

-- 3. Commento per documentazione
COMMENT ON COLUMN components.fornitore_id IS 'Fornitore predefinito per questo componente - usato per ordini automatici';

-- ============================================
-- FINE MIGRATION
-- ============================================

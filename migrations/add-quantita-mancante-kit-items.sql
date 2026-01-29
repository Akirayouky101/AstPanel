-- ============================================
-- AGGIUNTA CAMPO QUANTITA_MANCANTE
-- ============================================
-- Per tracciare i prodotti che mancano in magazzino
-- quando si crea un kit
-- ============================================

ALTER TABLE kit_items 
ADD COLUMN IF NOT EXISTS quantita_mancante DECIMAL(10,2) DEFAULT 0;

COMMENT ON COLUMN kit_items.quantita_mancante IS 'Quantità richiesta ma non disponibile in magazzino al momento della creazione';

-- ============================================
-- FINE MIGRATION
-- ============================================

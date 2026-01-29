-- ============================================
-- SOFT DELETE PER COMPONENTS
-- ============================================
-- Permette di "eliminare" prodotti mantenendo
-- i dati storici per kit e movimenti
-- ============================================

-- 1. Aggiungi campo stato a components
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS stato VARCHAR(20) DEFAULT 'attivo';

-- 2. Aggiungi campo deleted_at per tracking
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 3. Aggiungi campo deleted_by per audit
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES users(id);

-- 4. Indice per performance (solo prodotti attivi)
CREATE INDEX IF NOT EXISTS idx_components_stato ON components(stato) WHERE stato = 'attivo';

-- 5. Commenti
COMMENT ON COLUMN components.stato IS 'Stato del prodotto: attivo, eliminato';
COMMENT ON COLUMN components.deleted_at IS 'Data eliminazione logica';
COMMENT ON COLUMN components.deleted_by IS 'Utente che ha eliminato il prodotto';

-- ============================================
-- FINE MIGRATION
-- ============================================

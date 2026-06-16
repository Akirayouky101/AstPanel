-- =====================================================
-- Aggiunge colonna comune_id alla tabella clients
-- Collega ogni scuola al suo comune di riferimento
-- =====================================================

ALTER TABLE clients
ADD COLUMN IF NOT EXISTS comune_id UUID REFERENCES clients(id) ON DELETE SET NULL;

-- Index per query veloci (trova tutte le scuole di un comune)
CREATE INDEX IF NOT EXISTS idx_clients_comune_id ON clients(comune_id);

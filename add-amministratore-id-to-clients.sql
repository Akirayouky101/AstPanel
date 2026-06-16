-- =====================================================
-- Aggiunge colonna amministratore_id alla tabella clients
-- Collega ogni condominio al suo amministratore
-- =====================================================

ALTER TABLE clients
ADD COLUMN IF NOT EXISTS amministratore_id UUID REFERENCES clients(id) ON DELETE SET NULL;

-- Index per query veloci (trova tutti i condomini di un amministratore)
CREATE INDEX IF NOT EXISTS idx_clients_amministratore_id ON clients(amministratore_id);

-- ============================================================
-- ADD azienda_id TO clients
-- Supporto strutture collegate ad un'azienda in anagrafica clienti
-- ============================================================

ALTER TABLE clients
    ADD COLUMN IF NOT EXISTS azienda_id UUID REFERENCES aziende(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_clients_azienda_id ON clients(azienda_id);

DO $$ BEGIN
    RAISE NOTICE '✅ Colonna azienda_id aggiunta a clients e indice creato se necessario';
END $$;

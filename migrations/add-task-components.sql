-- ================================================
-- MIGRATION: Task Components System
-- Data: 4 dicembre 2025
-- Descrizione: Gestione componenti/materiali per lavorazioni
-- ================================================

-- Tabella per associare prodotti magazzino alle lavorazioni
CREATE TABLE IF NOT EXISTS task_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    prodotto_id UUID REFERENCES warehouse_products(id) ON DELETE SET NULL,
    quantita_richiesta DECIMAL(10,2) NOT NULL,
    quantita_utilizzata DECIMAL(10,2) DEFAULT 0,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_task_components_task ON task_components(task_id);
CREATE INDEX IF NOT EXISTS idx_task_components_product ON task_components(prodotto_id);

-- Trigger per timestamp
CREATE OR REPLACE FUNCTION update_task_components_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_components_timestamp
    BEFORE UPDATE ON task_components
    FOR EACH ROW
    EXECUTE FUNCTION update_task_components_timestamp();

-- Commenti
COMMENT ON TABLE task_components IS 'Associazione materiali/componenti alle lavorazioni';
COMMENT ON COLUMN task_components.quantita_richiesta IS 'Quantità necessaria per la lavorazione';
COMMENT ON COLUMN task_components.quantita_utilizzata IS 'Quantità effettivamente utilizzata';

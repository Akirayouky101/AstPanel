-- ================================================
-- MIGRATION: Task Creation Wizard Support
-- Data: 4 dicembre 2025
-- Descrizione: Campi aggiuntivi per wizard lavorazioni
-- ================================================

-- 1. Aggiungi campi wizard alla tabella tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS indirizzo_lavoro TEXT,
ADD COLUMN IF NOT EXISTS coordinate_gps POINT,
ADD COLUMN IF NOT EXISTS ore_stimate DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS costo_stimato DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS note_interne TEXT,
ADD COLUMN IF NOT EXISTS categoria VARCHAR(100),
ADD COLUMN IF NOT EXISTS tags TEXT[],
ADD COLUMN IF NOT EXISTS wizard_completed BOOLEAN DEFAULT FALSE;

-- 2. Indici per performance
CREATE INDEX IF NOT EXISTS idx_tasks_categoria ON tasks(categoria);
CREATE INDEX IF NOT EXISTS idx_tasks_coordinate ON tasks USING GIST(coordinate_gps) WHERE coordinate_gps IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_wizard_completed ON tasks(wizard_completed);

-- 3. Funzione per calcolo coordinate da indirizzo (placeholder)
CREATE OR REPLACE FUNCTION geocode_address(p_address TEXT)
RETURNS POINT AS $$
BEGIN
    -- Placeholder per integrazione geocoding
    -- In produzione, usare API Google Maps o Nominatim
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Commenti
COMMENT ON COLUMN tasks.indirizzo_lavoro IS 'Indirizzo completo dove si svolge la lavorazione';
COMMENT ON COLUMN tasks.coordinate_gps IS 'Coordinate GPS (lat, lon) per geolocalizzazione';
COMMENT ON COLUMN tasks.ore_stimate IS 'Ore di lavoro stimate per completamento';
COMMENT ON COLUMN tasks.costo_stimato IS 'Costo stimato totale (manodopera + materiali)';
COMMENT ON COLUMN tasks.categoria IS 'Categoria lavorazione (manutenzione, installazione, riparazione, etc)';
COMMENT ON COLUMN tasks.wizard_completed IS 'Flag per indicare se il wizard è stato completato';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'tasks' AND column_name IN ('indirizzo_lavoro', 'coordinate_gps', 'ore_stimate');

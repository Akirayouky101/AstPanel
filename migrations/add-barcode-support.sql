-- ================================================
-- MIGRATION: Barcode/QR Code Support
-- Data: 4 dicembre 2025
-- Descrizione: Aggiunge supporto barcode/QR per componenti
-- ================================================

-- 1. Aggiungi campo barcode alla tabella components
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS barcode VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS qr_code_data TEXT;

-- 2. Crea indice per ricerca rapida barcode
CREATE INDEX IF NOT EXISTS idx_components_barcode ON components(barcode) WHERE barcode IS NOT NULL;

-- 3. Funzione per generare barcode automatico se non esiste
CREATE OR REPLACE FUNCTION generate_component_barcode()
RETURNS TRIGGER AS $$
BEGIN
    -- Se non ha barcode, genera uno basato su codice prodotto o ID
    IF NEW.barcode IS NULL THEN
        IF NEW.code IS NOT NULL AND NEW.code != '' THEN
            NEW.barcode := 'COMP-' || NEW.code;
        ELSE
            NEW.barcode := 'COMP-' || SUBSTRING(NEW.id::TEXT FROM 1 FOR 8);
        END IF;
    END IF;
    
    -- Genera QR code data (JSON con info componente)
    NEW.qr_code_data := json_build_object(
        'id', NEW.id,
        'code', NEW.code,
        'name', NEW.name,
        'barcode', NEW.barcode,
        'category', NEW.category
    )::TEXT;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger per generare barcode automaticamente
DROP TRIGGER IF EXISTS trigger_generate_barcode ON components;
CREATE TRIGGER trigger_generate_barcode
    BEFORE INSERT OR UPDATE ON components
    FOR EACH ROW
    EXECUTE FUNCTION generate_component_barcode();

-- 5. Funzione per cercare componente tramite barcode
CREATE OR REPLACE FUNCTION find_component_by_barcode(p_barcode VARCHAR)
RETURNS TABLE (
    id UUID,
    code VARCHAR,
    name VARCHAR,
    category VARCHAR,
    quantita_magazzino INTEGER,
    quantita_minima INTEGER,
    unita_misura VARCHAR,
    barcode VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.code,
        c.name,
        c.category,
        c.quantita_magazzino,
        c.quantita_minima,
        c.unita_misura,
        c.barcode
    FROM components c
    WHERE c.barcode = p_barcode
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 6. Genera barcode per componenti esistenti
UPDATE components 
SET barcode = CASE 
    WHEN code IS NOT NULL AND code != '' THEN 'COMP-' || code
    ELSE 'COMP-' || SUBSTRING(id::TEXT FROM 1 FOR 8)
END
WHERE barcode IS NULL;

-- 7. Commento
COMMENT ON COLUMN components.barcode IS 'Codice barcode/QR univoco per identificazione rapida componente';
COMMENT ON COLUMN components.qr_code_data IS 'Dati JSON per generazione QR code stampabile';
COMMENT ON FUNCTION find_component_by_barcode IS 'Ricerca componente tramite scan barcode/QR';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT barcode, code, name FROM components LIMIT 10;

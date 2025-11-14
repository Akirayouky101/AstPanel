-- Migration: Add Products Warehouse System
-- This creates a complete warehouse/inventory system for products used in lavorazioni

-- The components table will be enhanced to work as a product warehouse
-- Add new columns if they don't exist

-- Add category field
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS categoria VARCHAR(50) DEFAULT 'altro';

-- Add stock tracking fields
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS scorta_minima DECIMAL(10,2) DEFAULT 0;

-- Add pricing
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS prezzo_unitario DECIMAL(10,2) DEFAULT NULL;

-- Add product code for better inventory management
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS codice VARCHAR(100) UNIQUE DEFAULT NULL;

-- Add notes field
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS note TEXT DEFAULT NULL;

-- Comments
COMMENT ON COLUMN components.categoria IS 'Product category: elettronica, meccanica, materiali, componentistica, altro';
COMMENT ON COLUMN components.scorta_minima IS 'Minimum stock level for alerts';
COMMENT ON COLUMN components.prezzo_unitario IS 'Unit price in euros';
COMMENT ON COLUMN components.codice IS 'Unique product code for inventory tracking';
COMMENT ON COLUMN components.note IS 'Additional notes (supplier, storage location, etc)';

-- Create index for better search performance
CREATE INDEX IF NOT EXISTS idx_components_categoria ON components(categoria);
CREATE INDEX IF NOT EXISTS idx_components_codice ON components(codice);
CREATE INDEX IF NOT EXISTS idx_components_quantita_disponibile ON components(quantita_disponibile);

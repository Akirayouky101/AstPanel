-- Tabella categorie magazzino
CREATE TABLE IF NOT EXISTS warehouse_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabella prodotti magazzino
CREATE TABLE IF NOT EXISTS warehouse_products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES warehouse_categories(id) ON DELETE SET NULL,
    sku VARCHAR(100),
    description TEXT,
    quantity INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    unit VARCHAR(20) DEFAULT 'pz',
    price DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_warehouse_products_category ON warehouse_products(category_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_products_sku ON warehouse_products(sku);
CREATE INDEX IF NOT EXISTS idx_warehouse_products_quantity ON warehouse_products(quantity);

-- Trigger per aggiornare updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_warehouse_categories_updated_at BEFORE UPDATE ON warehouse_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_warehouse_products_updated_at BEFORE UPDATE ON warehouse_products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Commenti per documentazione
COMMENT ON TABLE warehouse_categories IS 'Categorie per organizzare i prodotti del magazzino';
COMMENT ON TABLE warehouse_products IS 'Prodotti disponibili in magazzino con quantità e prezzi';

-- 1. Flag "ha seriale" sulla tabella prodotti/componenti
ALTER TABLE components
ADD COLUMN IF NOT EXISTS ha_seriale BOOLEAN DEFAULT false;

-- 2. Array seriali ricevuti su ogni riga dell'ordine fornitore
ALTER TABLE ordini_fornitore_items
ADD COLUMN IF NOT EXISTS seriali TEXT[] DEFAULT '{}';

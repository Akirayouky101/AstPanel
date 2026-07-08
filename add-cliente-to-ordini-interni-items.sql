-- Aggiunge riferimento cliente per singola riga di ordine interno
-- (uso interno — permette di dividere materiali per cliente diverso nello stesso ordine)
ALTER TABLE ordini_interni_items
  ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cliente_nome_cache VARCHAR(200);

CREATE INDEX IF NOT EXISTS idx_ordini_interni_items_cliente ON ordini_interni_items(cliente_id);

SELECT 'cliente_id aggiunto a ordini_interni_items' AS status;

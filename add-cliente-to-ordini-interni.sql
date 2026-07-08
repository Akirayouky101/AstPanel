-- Aggiunge riferimento cliente agli ordini interni (uso interno, non va al fornitore)
ALTER TABLE ordini_interni
  ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cliente_nome_cache VARCHAR(200);  -- cache nome per display rapido

CREATE INDEX IF NOT EXISTS idx_ordini_interni_cliente ON ordini_interni(cliente_id);

SELECT 'cliente_id aggiunto a ordini_interni' AS status;

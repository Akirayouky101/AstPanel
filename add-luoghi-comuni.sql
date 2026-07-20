-- =====================================================
-- Aggiunge supporto per "luoghi" collegati ai comuni
-- Usa la tabella clients esistente con tipo_cliente='luogo'
-- Stessa FK comune_id usata dalle scuole
-- =====================================================

-- Verifica che la colonna comune_id esista (dovrebbe già esserci)
ALTER TABLE clients
    ADD COLUMN IF NOT EXISTS comune_id uuid REFERENCES clients(id) ON DELETE SET NULL;

-- Indice per query veloci luoghi per comune
CREATE INDEX IF NOT EXISTS idx_clients_comune_id ON clients(comune_id);

-- Verifica i tipi esistenti e i nuovi luoghi
SELECT tipo_cliente, COUNT(*) as totale
FROM clients
WHERE tipo_cliente IN ('comune','scuola','struttura','luogo')
GROUP BY tipo_cliente
ORDER BY tipo_cliente;

SELECT 'Supporto luoghi attivato' AS status;

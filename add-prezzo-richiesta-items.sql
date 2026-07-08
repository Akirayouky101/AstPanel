-- Aggiunge prezzo risposta fornitore agli articoli della richiesta preventivo
ALTER TABLE richieste_preventivo_items
  ADD COLUMN IF NOT EXISTS prezzo_unitario DECIMAL(12,2) DEFAULT NULL;

-- Verifica
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'richieste_preventivo_items' AND column_name = 'prezzo_unitario';

-- Aggiunge colonne data_inizio, data_fine e note alla tabella requests
-- Per gestire il periodo delle richieste (ferie, permessi, etc.) e le note di approvazione/rifiuto

ALTER TABLE requests 
ADD COLUMN IF NOT EXISTS data_inizio DATE,
ADD COLUMN IF NOT EXISTS data_fine DATE,
ADD COLUMN IF NOT EXISTS note TEXT;

-- Aggiungi commenti per documentare le colonne
COMMENT ON COLUMN requests.data_inizio IS 'Data inizio del periodo richiesto (es. inizio ferie)';
COMMENT ON COLUMN requests.data_fine IS 'Data fine del periodo richiesto (es. fine ferie)';
COMMENT ON COLUMN requests.note IS 'Note di approvazione o rifiuto da parte dell admin';

-- Verifica le colonne create
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'requests'
AND column_name IN ('data_inizio', 'data_fine', 'note');

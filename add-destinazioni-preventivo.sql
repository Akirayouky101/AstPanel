-- Aggiunge supporto ai "Set di Consegna" nelle richieste preventivo
-- Esegui nel Supabase SQL Editor

-- Colonna destinazioni (JSON array) nella richiesta principale
ALTER TABLE richieste_preventivo_fornitori
ADD COLUMN IF NOT EXISTS destinazioni JSONB DEFAULT '[]'::jsonb;

-- Colonna destinazione (ID del set) su ogni riga articolo
ALTER TABLE richieste_preventivo_items
ADD COLUMN IF NOT EXISTS destinazione_id TEXT;

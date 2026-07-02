-- Aggiunge la colonna 'note' alla tabella richieste_preventivo_items
-- Esegui nel Supabase SQL Editor

ALTER TABLE richieste_preventivo_items 
ADD COLUMN IF NOT EXISTS note TEXT;

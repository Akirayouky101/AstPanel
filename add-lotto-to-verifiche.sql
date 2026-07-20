-- Aggiunge la colonna lotto alla tabella verifiche
ALTER TABLE verifiche
ADD COLUMN IF NOT EXISTS lotto TEXT;

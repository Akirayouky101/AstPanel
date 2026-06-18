-- Aggiunge colonna logo_url alla tabella fornitori
ALTER TABLE fornitori
ADD COLUMN IF NOT EXISTS logo_url TEXT DEFAULT NULL;

COMMENT ON COLUMN fornitori.logo_url IS 'URL immagine logo del fornitore (link esterno o base64)';

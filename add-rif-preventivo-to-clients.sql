-- Aggiunge colonna rif_preventivo alla tabella clients (uso interno)
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS rif_preventivo TEXT;

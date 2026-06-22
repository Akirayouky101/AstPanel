-- Aggiunge campi sede legale alla tabella clients
ALTER TABLE clients
    ADD COLUMN IF NOT EXISTS sede_legale_indirizzo TEXT,
    ADD COLUMN IF NOT EXISTS sede_legale_citta VARCHAR(100),
    ADD COLUMN IF NOT EXISTS sede_legale_provincia VARCHAR(10),
    ADD COLUMN IF NOT EXISTS sede_legale_cap VARCHAR(10);

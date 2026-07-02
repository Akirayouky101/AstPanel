-- Aggiunge la colonna email_ufficio alla tabella fornitori
ALTER TABLE fornitori
    ADD COLUMN IF NOT EXISTS email_ufficio VARCHAR(200);

COMMENT ON COLUMN fornitori.email_ufficio IS 'Email ufficio/amministrazione del fornitore (usata opzionalmente per copia degli ordini)';

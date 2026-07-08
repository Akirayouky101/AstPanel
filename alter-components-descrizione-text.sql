-- Rimuove il limite VARCHAR(255) dalla descrizione/nome dei componenti
-- Ora può contenere testi lunghi

ALTER TABLE components
  ALTER COLUMN nome TYPE TEXT,
  ALTER COLUMN descrizione TYPE TEXT;

-- Verifica
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'components'
  AND column_name IN ('nome', 'descrizione');

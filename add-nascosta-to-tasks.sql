-- Aggiunge flag "nascosta" alle lavorazioni
-- Le lavorazioni nascoste non appaiono nel pannello ma non vengono eliminate
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS nascosta BOOLEAN DEFAULT FALSE;

-- Verifica
SELECT id, titolo, nascosta FROM tasks WHERE nascosta = TRUE LIMIT 5;

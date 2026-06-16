-- Aggiunge campi orario alle lavorazioni
-- Esegui questo script su Supabase SQL Editor

ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS ora_inizio TIME,
ADD COLUMN IF NOT EXISTS ora_fine TIME;

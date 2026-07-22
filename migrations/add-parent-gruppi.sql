-- Aggiunge parent_id a gruppi_schede per permettere gruppi annidati (es: Comune → Scuola)
ALTER TABLE gruppi_schede
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES gruppi_schede(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_gruppi_schede_parent_id ON gruppi_schede(parent_id);

-- Crea tabella gruppi schede (cartelle)
CREATE TABLE IF NOT EXISTS gruppi_schede (
  id        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome      TEXT NOT NULL,
  note      TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Aggiungi gruppo_id a schede_verifica
ALTER TABLE schede_verifica
  ADD COLUMN IF NOT EXISTS gruppo_id UUID REFERENCES gruppi_schede(id) ON DELETE SET NULL;

-- Index per query veloci
CREATE INDEX IF NOT EXISTS idx_schede_verifica_gruppo_id ON schede_verifica(gruppo_id);

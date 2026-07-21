-- ============================================================
-- Tabella: schede_verifica
-- Schede di verifica rapida componenti elettrici (quadri)
-- ============================================================

CREATE TABLE IF NOT EXISTS schede_verifica (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    luogo      TEXT,
    quadro     TEXT,
    righe      JSONB       NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Aggiorna updated_at automaticamente ad ogni UPDATE
CREATE OR REPLACE FUNCTION update_schede_verifica_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_schede_verifica_updated_at ON schede_verifica;
CREATE TRIGGER trg_schede_verifica_updated_at
    BEFORE UPDATE ON schede_verifica
    FOR EACH ROW EXECUTE FUNCTION update_schede_verifica_updated_at();

-- RLS: accesso libero (schede condivise tra tecnici interni)
ALTER TABLE schede_verifica ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "schede_verifica_all" ON schede_verifica;
CREATE POLICY "schede_verifica_all" ON schede_verifica
    FOR ALL USING (true) WITH CHECK (true);

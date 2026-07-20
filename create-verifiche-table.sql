-- Tabella verifiche semestrali/annuali impianti
-- Usata da Admin/verifiche-semestrali-comune.html

CREATE TABLE IF NOT EXISTS verifiche (
    id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    tipo_verifica TEXT        NOT NULL DEFAULT 'semestrale'
                              CHECK (tipo_verifica IN ('semestrale','annuale')),
    settore       TEXT        NOT NULL DEFAULT 'comune',
    cliente_id    UUID        REFERENCES clients(id) ON DELETE CASCADE,
    luogo_nome    TEXT,
    data_verifica DATE,
    piano         TEXT,
    ubicazione    TEXT,
    marca_n_poli  TEXT,
    codice        TEXT,
    esito         TEXT        NOT NULL DEFAULT 'conforme'
                              CHECK (esito IN ('conforme','non_conforme','da_verificare')),
    data_prossima DATE,
    note          TEXT,
    created_by    UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_verifiche_settore       ON verifiche(settore);
CREATE INDEX IF NOT EXISTS idx_verifiche_cliente       ON verifiche(cliente_id);
CREATE INDEX IF NOT EXISTS idx_verifiche_data_verifica ON verifiche(data_verifica DESC);
CREATE INDEX IF NOT EXISTS idx_verifiche_tipo          ON verifiche(tipo_verifica);

-- RLS
ALTER TABLE verifiche ENABLE ROW LEVEL SECURITY;

CREATE POLICY "verifiche_all_authenticated"
    ON verifiche FOR ALL TO authenticated
    USING (true) WITH CHECK (true);

SELECT '✅ Tabella verifiche creata' AS status;

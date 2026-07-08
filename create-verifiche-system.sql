-- =====================================================
-- Sistema Verifiche Semestrali / Annuali
-- Settori: Comune, Azienda, Privato
-- =====================================================

CREATE TABLE IF NOT EXISTS verifiche (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Classificazione
    tipo_verifica VARCHAR(20) NOT NULL DEFAULT 'semestrale',
    -- 'semestrale', 'annuale'

    settore VARCHAR(20) NOT NULL DEFAULT 'comune',
    -- 'comune', 'azienda', 'privato'

    -- Luogo / Cliente
    cliente_id   UUID REFERENCES clients(id) ON DELETE SET NULL,
    luogo_nome   VARCHAR(200),   -- cache del nome cliente o testo libero

    -- Dati verifica
    piano        VARCHAR(50),    -- es: Piano Terra, P1, Interrato
    ubicazione   VARCHAR(300),   -- es: Corridoio nord, Locale caldaia
    marca_n_poli VARCHAR(200),   -- es: ABB 4P, Schneider 2P
    codice       VARCHAR(100),   -- codice identificativo quadro/dispositivo

    -- Esito
    esito        VARCHAR(30) NOT NULL DEFAULT 'conforme',
    -- 'conforme', 'non_conforme', 'condizionato'
    note         TEXT,

    -- Date
    data_verifica      DATE NOT NULL DEFAULT CURRENT_DATE,
    data_prossima      DATE,          -- prossima verifica prevista

    -- Metadata
    created_by   UUID,
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_verifiche_cliente     ON verifiche(cliente_id);
CREATE INDEX IF NOT EXISTS idx_verifiche_settore     ON verifiche(settore);
CREATE INDEX IF NOT EXISTS idx_verifiche_tipo        ON verifiche(tipo_verifica);
CREATE INDEX IF NOT EXISTS idx_verifiche_esito       ON verifiche(esito);
CREATE INDEX IF NOT EXISTS idx_verifiche_data        ON verifiche(data_verifica);

-- RLS
ALTER TABLE verifiche ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "verifiche_all" ON verifiche;
CREATE POLICY "verifiche_all" ON verifiche FOR ALL USING (true) WITH CHECK (true);

-- Verifica
SELECT 'Tabella verifiche creata' AS status;

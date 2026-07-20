-- =====================================================
-- Vendita al Banco
-- Documento di vendita con scarico automatico magazzino
-- =====================================================

CREATE TABLE IF NOT EXISTS vendite_banco (
    id              uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    numero          text        NOT NULL UNIQUE,  -- es. VB-2026-001
    data_vendita    date        NOT NULL DEFAULT CURRENT_DATE,
    cliente_nome    text,                          -- nome libero o da anagrafica
    cliente_id      uuid        REFERENCES clients(id) ON DELETE SET NULL,
    operatore_id    uuid        REFERENCES users(id),
    operatore_nome  text,
    subtotale       numeric(10,2) DEFAULT 0,
    sconto_perc     numeric(5,2) DEFAULT 0,
    totale          numeric(10,2) DEFAULT 0,
    note            text,
    stato           text        DEFAULT 'completata' CHECK (stato IN ('completata', 'annullata')),
    created_at      timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vendite_banco_items (
    id              uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    vendita_id      uuid        NOT NULL REFERENCES vendite_banco(id) ON DELETE CASCADE,
    prodotto_id     uuid        REFERENCES components(id) ON DELETE SET NULL,
    prodotto_codice text,
    prodotto_nome   text        NOT NULL,
    quantita        numeric(10,3) NOT NULL,
    um              text        DEFAULT 'pz',
    prezzo_unitario numeric(10,2) DEFAULT 0,
    importo         numeric(10,2) DEFAULT 0
);

-- Sequenza per numero progressivo
CREATE SEQUENCE IF NOT EXISTS vendite_banco_seq START 1;

-- Indici
CREATE INDEX IF NOT EXISTS idx_vendite_banco_data ON vendite_banco(data_vendita DESC);
CREATE INDEX IF NOT EXISTS idx_vendite_banco_items_vendita ON vendite_banco_items(vendita_id);

-- RLS
ALTER TABLE vendite_banco ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendite_banco_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Auth users manage vendite banco" ON vendite_banco;
CREATE POLICY "Auth users manage vendite banco" ON vendite_banco
    FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth users manage vendite banco items" ON vendite_banco_items;
CREATE POLICY "Auth users manage vendite banco items" ON vendite_banco_items
    FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

SELECT 'Tabelle vendite_banco create' AS status;

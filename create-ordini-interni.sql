-- =====================================================
-- SISTEMA ORDINI INTERNI
-- =====================================================
-- Ordini verbali o da approvare senza preventivo formale
-- Due tipologie:
--   da_approvare  = ordine da fare, richiede approvazione del titolare prima
--   da_ratificare = ordine già fatto verbalmente, richiede ratifica a posteriori
-- =====================================================

-- 1. TABELLA ORDINI INTERNI
CREATE TABLE IF NOT EXISTS ordini_interni (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Numerazione
    numero VARCHAR(50) UNIQUE NOT NULL, -- es: "OI-2026-001"

    -- Tipo ordine
    tipo VARCHAR(30) NOT NULL DEFAULT 'da_approvare',
    -- 'da_approvare'  = ordine da fare, in attesa di approvazione
    -- 'da_ratificare' = ordine già effettuato verbalmente, da ratificare

    -- Stato
    stato VARCHAR(30) NOT NULL DEFAULT 'bozza',
    -- 'bozza'      → in compilazione
    -- 'in_attesa'  → inviato per approvazione/ratifica
    -- 'approvato'  → approvato/ratificato
    -- 'annullato'  → annullato

    -- Fornitore (può essere libero o collegato alla tabella fornitori)
    fornitore_id UUID REFERENCES fornitori(id) ON DELETE SET NULL,
    fornitore_nome VARCHAR(200),        -- Cache o testo libero
    fornitore_email VARCHAR(200),
    fornitore_telefono VARCHAR(50),
    fornitore_riferimento VARCHAR(200), -- Es: nome del commerciale contattato

    -- Dati ordine
    oggetto VARCHAR(500) NOT NULL,
    descrizione TEXT,
    data_ordine DATE NOT NULL DEFAULT CURRENT_DATE,
    data_consegna_prevista DATE,        -- Data prevista consegna/ricezione
    numero_ordine_fornitore VARCHAR(100), -- Eventuale numero ordine dato dal fornitore

    -- Importi
    subtotale DECIMAL(12,2) DEFAULT 0,
    sconto_percentuale DECIMAL(5,2) DEFAULT 0,
    sconto_importo DECIMAL(12,2) DEFAULT 0,
    iva_percentuale DECIMAL(5,2) DEFAULT 22,
    totale_iva DECIMAL(12,2) DEFAULT 0,
    totale DECIMAL(12,2) DEFAULT 0,

    -- Note
    note TEXT,
    note_interne TEXT,

    -- Approvazione / Ratifica
    approvato_da UUID REFERENCES users(id) ON DELETE SET NULL,
    approvato_da_nome VARCHAR(200),
    data_approvazione TIMESTAMPTZ,
    note_approvazione TEXT,

    -- Collegamento a progetto/preventivo (opzionale)
    preventivo_id UUID REFERENCES preventivi(id) ON DELETE SET NULL,

    -- Metadata
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABELLA VOCI ORDINE
CREATE TABLE IF NOT EXISTS ordini_interni_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    ordine_id UUID NOT NULL REFERENCES ordini_interni(id) ON DELETE CASCADE,

    -- Collegamento magazzino (opzionale)
    prodotto_id UUID REFERENCES components(id) ON DELETE SET NULL,

    -- Dati voce (cache o inserimento manuale)
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    um VARCHAR(20) DEFAULT 'pz',

    -- Quantità e prezzi
    quantita DECIMAL(10,2) NOT NULL DEFAULT 1,
    prezzo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    sconto_percentuale DECIMAL(5,2) DEFAULT 0,
    importo DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Note sulla voce
    note VARCHAR(500),

    -- Posizione per ordinamento
    posizione INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. FUNZIONE NUMERAZIONE AUTOMATICA
CREATE OR REPLACE FUNCTION generate_ordine_interno_numero()
RETURNS VARCHAR AS $$
DECLARE
    anno INTEGER;
    seq  INTEGER;
    numero VARCHAR;
BEGIN
    anno := EXTRACT(YEAR FROM NOW());
    SELECT COALESCE(MAX(
        CAST(REGEXP_REPLACE(oi.numero, '^OI-\d{4}-', '') AS INTEGER)
    ), 0) + 1
    INTO seq
    FROM ordini_interni oi
    WHERE oi.numero LIKE 'OI-' || anno || '-%';
    numero := 'OI-' || anno || '-' || LPAD(seq::TEXT, 3, '0');
    RETURN numero;
END;
$$ LANGUAGE plpgsql;

-- 4. TRIGGER updated_at
CREATE OR REPLACE FUNCTION update_ordine_interno_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ordini_interni_updated_at ON ordini_interni;
CREATE TRIGGER trg_ordini_interni_updated_at
    BEFORE UPDATE ON ordini_interni
    FOR EACH ROW EXECUTE FUNCTION update_ordine_interno_updated_at();

-- 5. INDICI
CREATE INDEX IF NOT EXISTS idx_ordini_interni_stato ON ordini_interni(stato);
CREATE INDEX IF NOT EXISTS idx_ordini_interni_tipo  ON ordini_interni(tipo);
CREATE INDEX IF NOT EXISTS idx_ordini_interni_created_at ON ordini_interni(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ordini_interni_items_ordine ON ordini_interni_items(ordine_id);

-- 6. DISABILITA RLS (coerente con il resto del progetto)
ALTER TABLE ordini_interni DISABLE ROW LEVEL SECURITY;
ALTER TABLE ordini_interni_items DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ESECUZIONE COMPLETATA
-- Tabelle: ordini_interni, ordini_interni_items
-- Funzione: generate_ordine_interno_numero()
-- Numerazione: OI-YYYY-NNN
-- =====================================================

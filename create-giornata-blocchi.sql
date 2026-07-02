-- =====================================================
-- GIORNATA BLOCCHI - Blocchi manuali giornalieri per dipendente
-- =====================================================
-- Permette di bloccare fasce orarie nella giornata di un dipendente
-- (es. Magazzino 08:00-10:00, Riunione 11:00-12:00, ecc.)
-- Separata dalla tabella tasks: è uno strumento di pianificazione
-- visiva rapida, non un task formale.
-- =====================================================

CREATE TABLE IF NOT EXISTS giornata_blocchi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Dipendente (obbligatorio)
    dipendente_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Data del blocco
    data DATE NOT NULL,

    -- Orari
    ora_inizio TIME NOT NULL,
    ora_fine   TIME NOT NULL,

    -- Descrizione
    titolo VARCHAR(200) NOT NULL,

    -- Tipo blocco (preset)
    -- 'magazzino' | 'cantiere' | 'riunione' | 'trasferta' | 'ufficio' | 'formazione' | 'pausa' | 'altro'
    tipo VARCHAR(50) DEFAULT 'altro',

    -- Note opzionali
    note TEXT,

    -- Chi ha creato il blocco
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Vincolo: ora_fine deve essere dopo ora_inizio
    CONSTRAINT check_orari CHECK (ora_fine > ora_inizio)
);

-- Indice principale: dipendente + data (query più comune)
CREATE INDEX IF NOT EXISTS idx_giornata_blocchi_dip_data
    ON giornata_blocchi(dipendente_id, data);

-- Indice per data (utile per query globali per giorno)
CREATE INDEX IF NOT EXISTS idx_giornata_blocchi_data
    ON giornata_blocchi(data);

-- Disabilita RLS (coerente con il resto del progetto)
ALTER TABLE giornata_blocchi DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ESECUZIONE COMPLETATA
-- Tabella: giornata_blocchi
-- =====================================================

-- ============================================================
-- RICHIESTE PREVENTIVO FORNITORI
-- Esegui nel Supabase SQL Editor
-- ============================================================

-- Tabella principale
CREATE TABLE IF NOT EXISTS richieste_preventivo_fornitori (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero VARCHAR(30) UNIQUE NOT NULL,
    fornitore_id UUID REFERENCES fornitori(id) ON DELETE SET NULL,
    fornitore_nome VARCHAR(200),
    oggetto TEXT NOT NULL,
    data_richiesta DATE NOT NULL DEFAULT CURRENT_DATE,
    data_risposta_entro DATE,
    stato VARCHAR(20) DEFAULT 'da_inviare',
    -- 'da_inviare', 'inviato', 'risposto', 'accettato', 'rifiutato', 'annullato'
    note_interne TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabella righe/articoli
CREATE TABLE IF NOT EXISTS richieste_preventivo_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    richiesta_id UUID NOT NULL REFERENCES richieste_preventivo_fornitori(id) ON DELETE CASCADE,
    prodotto_id UUID REFERENCES components(id) ON DELETE SET NULL,
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    um VARCHAR(20) DEFAULT 'pz',
    quantita DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici
CREATE INDEX IF NOT EXISTS idx_richieste_prev_fornitore ON richieste_preventivo_fornitori(fornitore_id);
CREATE INDEX IF NOT EXISTS idx_richieste_prev_stato ON richieste_preventivo_fornitori(stato);
CREATE INDEX IF NOT EXISTS idx_richieste_prev_items ON richieste_preventivo_items(richiesta_id);

-- Funzione numerazione automatica (RQ-2026-001)
CREATE OR REPLACE FUNCTION generate_richiesta_preventivo_numero()
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    anno TEXT;
    ultimo_numero INTEGER;
    nuovo_numero TEXT;
BEGIN
    anno := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;

    SELECT COALESCE(
        MAX(CAST(SUBSTRING(numero FROM 'RQ-' || anno || '-(\d+)') AS INTEGER)),
        0
    ) INTO ultimo_numero
    FROM richieste_preventivo_fornitori
    WHERE numero LIKE 'RQ-' || anno || '-%';

    nuovo_numero := 'RQ-' || anno || '-' || LPAD((ultimo_numero + 1)::TEXT, 3, '0');
    RETURN nuovo_numero;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION generate_richiesta_preventivo_numero() TO authenticated;

-- RLS
ALTER TABLE richieste_preventivo_fornitori ENABLE ROW LEVEL SECURITY;
ALTER TABLE richieste_preventivo_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rp_select"  ON richieste_preventivo_fornitori;
DROP POLICY IF EXISTS "rp_insert"  ON richieste_preventivo_fornitori;
DROP POLICY IF EXISTS "rp_update"  ON richieste_preventivo_fornitori;
DROP POLICY IF EXISTS "rp_delete"  ON richieste_preventivo_fornitori;

CREATE POLICY "rp_select" ON richieste_preventivo_fornitori FOR SELECT USING (true);
CREATE POLICY "rp_insert" ON richieste_preventivo_fornitori FOR INSERT WITH CHECK (true);
CREATE POLICY "rp_update" ON richieste_preventivo_fornitori FOR UPDATE USING (true);
CREATE POLICY "rp_delete" ON richieste_preventivo_fornitori FOR DELETE USING (true);

DROP POLICY IF EXISTS "rpi_select" ON richieste_preventivo_items;
DROP POLICY IF EXISTS "rpi_insert" ON richieste_preventivo_items;
DROP POLICY IF EXISTS "rpi_update" ON richieste_preventivo_items;
DROP POLICY IF EXISTS "rpi_delete" ON richieste_preventivo_items;

CREATE POLICY "rpi_select" ON richieste_preventivo_items FOR SELECT USING (true);
CREATE POLICY "rpi_insert" ON richieste_preventivo_items FOR INSERT WITH CHECK (true);
CREATE POLICY "rpi_update" ON richieste_preventivo_items FOR UPDATE USING (true);
CREATE POLICY "rpi_delete" ON richieste_preventivo_items FOR DELETE USING (true);

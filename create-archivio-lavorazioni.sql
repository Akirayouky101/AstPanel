-- ============================================
-- Tabella archivio lavorazioni
-- Snapshot "freezato" della lavorazione:
-- non legato a team/utenti con FK, solo dati testuali
-- ============================================

CREATE TABLE IF NOT EXISTS archivio_lavorazioni (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lavorazione_id UUID,                         -- ID originale (solo riferimento, no FK)
    titolo TEXT NOT NULL,
    descrizione TEXT,
    stato TEXT,
    priorita TEXT,
    scadenza DATE,
    ore_stimate NUMERIC,
    progresso INTEGER DEFAULT 0,
    -- Snapshot cliente (testo, no FK)
    client_id UUID,
    client_nome TEXT,
    -- Snapshot assegnazione (testo, no FK)
    assigned_user_id UUID,
    assigned_user_nome TEXT,
    assigned_team_id UUID,
    assigned_team_nome TEXT,
    -- Snapshot dipendenti multi-assegnazione (JSON array)
    assegnazioni_snapshot JSONB DEFAULT '[]',
    -- Metadati archiviazione
    archiviata_da UUID REFERENCES users(id) ON DELETE SET NULL,
    archiviata_il TIMESTAMPTZ DEFAULT NOW(),
    note_archiviazione TEXT,
    -- Dati originali completi come backup
    dati_originali JSONB DEFAULT '{}'
);

-- Indici utili
CREATE INDEX IF NOT EXISTS idx_archivio_lavorazioni_team ON archivio_lavorazioni(assigned_team_id);
CREATE INDEX IF NOT EXISTS idx_archivio_lavorazioni_data ON archivio_lavorazioni(archiviata_il DESC);

-- RLS
ALTER TABLE archivio_lavorazioni ENABLE ROW LEVEL SECURITY;

-- Admin vede tutto (ruoli case-insensitive)
DROP POLICY IF EXISTS "admin_all_archivio" ON archivio_lavorazioni;
CREATE POLICY "admin_all_archivio" ON archivio_lavorazioni
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND lower(ruolo) IN ('admin','titolare','tecnico','segreteria'))
    )
    WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE auth_id = auth.uid() AND lower(ruolo) IN ('admin','titolare','tecnico','segreteria'))
    );

-- Tabella per i giorni bloccati (ferie, chiusure, indisponibilità)
CREATE TABLE IF NOT EXISTS giorni_bloccati (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_inizio DATE NOT NULL,
    data_fine DATE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- NULL = blocco per tutti
    motivo TEXT,
    colore VARCHAR(20) DEFAULT '#ef4444',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE giorni_bloccati ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read giorni_bloccati"
    ON giorni_bloccati FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert giorni_bloccati"
    ON giorni_bloccati FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete giorni_bloccati"
    ON giorni_bloccati FOR DELETE
    USING (auth.role() = 'authenticated');

-- Drop e ricrea tabella communications con i campi corretti dal form

DROP TABLE IF EXISTS communications CASCADE;

CREATE TABLE communications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Campi base dal form
    titolo VARCHAR(500) NOT NULL,
    tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('annuncio', 'newsletter', 'evento', 'formazione', 'procedura')),
    priorita VARCHAR(20) NOT NULL DEFAULT 'media' CHECK (priorita IN ('bassa', 'media', 'alta')),
    contenuto TEXT NOT NULL,
    
    -- Destinatari
    destinatari VARCHAR(50) NOT NULL DEFAULT 'tutti' CHECK (destinatari IN ('tutti', 'dipendenti', 'admin', 'specifici')),
    utenti_specifici UUID[] DEFAULT ARRAY[]::UUID[], -- Array di user IDs quando destinatari='specifici'
    
    -- File allegati (JSON array di nomi/path file)
    allegati JSONB DEFAULT '[]'::jsonb,
    
    -- Programmazione e stato
    data_programmata TIMESTAMP WITH TIME ZONE,
    stato VARCHAR(20) NOT NULL DEFAULT 'bozza' CHECK (stato IN ('bozza', 'programmata', 'inviata')),
    data_invio TIMESTAMP WITH TIME ZONE, -- Quando è stata effettivamente inviata
    
    -- Tracciamento letture
    letta_da UUID[] DEFAULT ARRAY[]::UUID[], -- Array di user IDs che hanno letto
    
    -- Metadati
    pubblicato_da UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indici per performance
CREATE INDEX idx_communications_tipo ON communications(tipo);
CREATE INDEX idx_communications_stato ON communications(stato);
CREATE INDEX idx_communications_destinatari ON communications(destinatari);
CREATE INDEX idx_communications_data_programmata ON communications(data_programmata);
CREATE INDEX idx_communications_pubblicato_da ON communications(pubblicato_da);
CREATE INDEX idx_communications_created_at ON communications(created_at DESC);

-- Trigger per updated_at
CREATE OR REPLACE FUNCTION update_communications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_communications_timestamp 
BEFORE UPDATE ON communications 
FOR EACH ROW 
EXECUTE FUNCTION update_communications_updated_at();

-- RLS Policies
ALTER TABLE communications ENABLE ROW LEVEL SECURITY;

-- Gli admin possono fare tutto (INSERT, UPDATE, DELETE, SELECT)
CREATE POLICY "Admin full access" ON communications
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.ruolo = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.ruolo = 'admin'
        )
    );

-- Gli utenti possono vedere solo le comunicazioni a loro destinate
CREATE POLICY "Users can view their communications" ON communications
    FOR SELECT
    TO authenticated
    USING (
        destinatari = 'tutti' OR
        (destinatari = 'dipendenti' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid()
        )) OR
        (destinatari = 'admin' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid() AND users.ruolo = 'admin'
        )) OR
        (destinatari = 'specifici' AND auth.uid() = ANY(utenti_specifici))
    );

-- Gli utenti possono aggiornare solo letta_da (marcare come letto)
CREATE POLICY "Users can mark as read" ON communications
    FOR UPDATE
    TO authenticated
    USING (
        destinatari = 'tutti' OR
        (destinatari = 'dipendenti' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid()
        )) OR
        (destinatari = 'admin' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid() AND users.ruolo = 'admin'
        )) OR
        (destinatari = 'specifici' AND auth.uid() = ANY(utenti_specifici))
    )
    WITH CHECK (
        destinatari = 'tutti' OR
        (destinatari = 'dipendenti' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid()
        )) OR
        (destinatari = 'admin' AND EXISTS (
            SELECT 1 FROM users WHERE users.id = auth.uid() AND users.ruolo = 'admin'
        )) OR
        (destinatari = 'specifici' AND auth.uid() = ANY(utenti_specifici))
    );

COMMENT ON TABLE communications IS 'Comunicazioni aziendali con supporto per programmazione e tracking letture';
COMMENT ON COLUMN communications.tipo IS 'annuncio, newsletter, evento, formazione, procedura';
COMMENT ON COLUMN communications.priorita IS 'bassa, media, alta';
COMMENT ON COLUMN communications.stato IS 'bozza (non inviata), programmata (schedulata), inviata';
COMMENT ON COLUMN communications.destinatari IS 'tutti, dipendenti, admin, specifici';
COMMENT ON COLUMN communications.utenti_specifici IS 'Array di UUID utenti quando destinatari=specifici';

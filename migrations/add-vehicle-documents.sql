-- ============================================
-- SISTEMA DOCUMENTI VEICOLI
-- ============================================
-- Descrizione: Gestione upload documenti veicoli con cascade delete
-- Data: 2026-01-29
-- ============================================

-- Tabella documenti veicoli
CREATE TABLE IF NOT EXISTS vehicle_documents (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    nome_file varchar(255) NOT NULL,
    tipo_documento varchar(50) NOT NULL, -- libretto, assicurazione, revisione, bollo, contratto_noleggio, fattura, altro
    descrizione text,
    url_file text NOT NULL,
    mime_type varchar(100),
    dimensione_kb integer,
    data_scadenza date, -- Per documenti con scadenza (assicurazione, revisione, bollo)
    uploaded_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_vehicle_documents_vehicle ON vehicle_documents(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_documents_tipo ON vehicle_documents(tipo_documento);
CREATE INDEX IF NOT EXISTS idx_vehicle_documents_scadenza ON vehicle_documents(data_scadenza) WHERE data_scadenza IS NOT NULL;

-- RLS Policies
ALTER TABLE vehicle_documents ENABLE ROW LEVEL SECURITY;

-- Policy: Tutti gli utenti autenticati possono vedere i documenti
CREATE POLICY "Utenti autenticati possono vedere documenti veicoli"
    ON vehicle_documents FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Tutti gli utenti autenticati possono caricare documenti
CREATE POLICY "Utenti autenticati possono caricare documenti veicoli"
    ON vehicle_documents FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Tutti gli utenti autenticati possono aggiornare documenti
CREATE POLICY "Utenti autenticati possono aggiornare documenti veicoli"
    ON vehicle_documents FOR UPDATE
    TO authenticated
    USING (true);

-- Policy: Tutti gli utenti autenticati possono eliminare documenti
CREATE POLICY "Utenti autenticati possono eliminare documenti veicoli"
    ON vehicle_documents FOR DELETE
    TO authenticated
    USING (true);

-- Trigger per updated_at
CREATE OR REPLACE FUNCTION update_vehicle_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_vehicle_documents_updated_at
    BEFORE UPDATE ON vehicle_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_vehicle_documents_updated_at();

-- View documenti con info veicolo
CREATE OR REPLACE VIEW v_vehicle_documents AS
SELECT 
    vd.*,
    v.targa,
    v.marca,
    v.modello,
    v.proprieta,
    CONCAT(u.nome, ' ', u.cognome) as uploaded_by_name
FROM vehicle_documents vd
JOIN vehicles v ON vd.vehicle_id = v.id
LEFT JOIN utenti u ON vd.uploaded_by = u.id
ORDER BY vd.created_at DESC;

-- Commenti
COMMENT ON TABLE vehicle_documents IS 'Documenti caricati per ogni veicolo (libretto, assicurazione, fatture, ecc.)';
COMMENT ON COLUMN vehicle_documents.tipo_documento IS 'Tipologia: libretto, assicurazione, revisione, bollo, contratto_noleggio, fattura, altro';
COMMENT ON COLUMN vehicle_documents.data_scadenza IS 'Data scadenza per documenti con validità temporale';

-- Storage bucket per documenti veicoli (eseguire nel dashboard Supabase Storage)
-- Bucket name: vehicle-documents
-- Public: false
-- File size limit: 10MB
-- Allowed MIME types: image/*, application/pdf

-- Storage policies (eseguire dopo creazione bucket)
-- Policy: Utenti autenticati possono caricare
-- CREATE POLICY "Utenti autenticati possono caricare documenti veicoli"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'vehicle-documents');

-- Policy: Utenti autenticati possono leggere
-- CREATE POLICY "Utenti autenticati possono leggere documenti veicoli"
-- ON storage.objects FOR SELECT
-- TO authenticated
-- USING (bucket_id = 'vehicle-documents');

-- Policy: Utenti autenticati possono eliminare
-- CREATE POLICY "Utenti autenticati possono eliminare documenti veicoli"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'vehicle-documents');

-- ============================================
-- FINE MIGRATION
-- ============================================

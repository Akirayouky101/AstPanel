-- ================================================
-- MIGRATION: Firma Digitale + Report PDF
-- Data: 3 dicembre 2025
-- Descrizione: Aggiunge supporto per firma digitale cliente e report PDF
-- ================================================

-- 1. Aggiungere colonne alla tabella tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS firma_cliente TEXT,
ADD COLUMN IF NOT EXISTS firma_timestamp TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pdf_report_url TEXT;

-- 2. Aggiungere commenti per documentazione
COMMENT ON COLUMN tasks.firma_cliente IS 'Firma digitale del cliente in formato base64 (PNG)';
COMMENT ON COLUMN tasks.firma_timestamp IS 'Timestamp di quando il cliente ha firmato';
COMMENT ON COLUMN tasks.pdf_report_url IS 'URL pubblico del PDF report generato';

-- 3. Creare indice per migliorare performance queries
CREATE INDEX IF NOT EXISTS idx_tasks_firma 
ON tasks(firma_timestamp) 
WHERE firma_cliente IS NOT NULL;

-- 4. NOTA: Creare bucket Storage manualmente in Supabase Dashboard
-- - Vai su Storage > Create Bucket
-- - Nome bucket: "reports"
-- - Public: YES (per permettere download PDF)
-- - File size limit: 10MB
-- - Allowed MIME types: application/pdf, image/png

-- 5. RLS Policy per bucket reports (se necessario)
-- Eseguire solo se bucket richiede RLS
/*
CREATE POLICY "Users can upload own reports"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'reports' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can read own reports"
ON storage.objects FOR SELECT
USING (bucket_id = 'reports');

CREATE POLICY "Users can update own reports"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'reports' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
*/

-- 6. Verificare la migration
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'tasks'
  AND column_name IN ('firma_cliente', 'firma_timestamp', 'pdf_report_url');

-- Output atteso:
-- firma_cliente    | text           | YES
-- firma_timestamp  | timestamp with time zone | YES
-- pdf_report_url   | text           | YES

-- Aggiunge foto ai prodotti/componenti
ALTER TABLE components
  ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- Bucket pubblico per le foto prodotti
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-photos',
  'product-photos',
  true,
  5242880,   -- 5 MB max
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: chiunque può leggere (bucket pubblico), solo autenticati possono uploadare
DROP POLICY IF EXISTS "product_photos_public_read"  ON storage.objects;
DROP POLICY IF EXISTS "product_photos_auth_write"   ON storage.objects;

CREATE POLICY "product_photos_public_read"
  ON storage.objects FOR SELECT USING (bucket_id = 'product-photos');

CREATE POLICY "product_photos_auth_write"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'product-photos' AND auth.role() = 'authenticated');

CREATE POLICY "product_photos_auth_delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'product-photos' AND auth.role() = 'authenticated');

SELECT 'foto_url aggiunta + bucket product-photos creato' AS status;

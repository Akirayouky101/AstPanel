-- Add foto_profilo column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS foto_profilo TEXT;

-- Add comment to column
COMMENT ON COLUMN users.foto_profilo IS 'Base64 encoded profile photo (JPEG, max 400x400px, compressed)';

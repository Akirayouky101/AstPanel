-- Tabella note personali per l'admin panel
-- Esegui questo script una volta nel tuo progetto Supabase

CREATE TABLE IF NOT EXISTS notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titolo VARCHAR(500) NOT NULL,
    contenuto TEXT DEFAULT '',
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- Trigger per updated_at automatico
CREATE OR REPLACE FUNCTION update_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_notes_timestamp ON notes;
CREATE TRIGGER update_notes_timestamp
BEFORE UPDATE ON notes
FOR EACH ROW EXECUTE FUNCTION update_notes_updated_at();

-- Disabilita RLS (come le altre tabelle del sistema)
ALTER TABLE notes DISABLE ROW LEVEL SECURITY;

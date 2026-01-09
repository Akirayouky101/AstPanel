-- =====================================================
-- Aggiungi campo PIN alla tabella users esistente
-- =====================================================
-- Esegui questo script se hai già una tabella users senza il campo pin_code

-- Aggiungi colonna pin_code se non esiste
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10);

-- Aggiungi commento per documentazione
COMMENT ON COLUMN users.pin_code IS 'PIN per sicurezza extra (opzionale). Solo per utenti che richiedono verifica aggiuntiva.';

-- Verifica
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'pin_code';

SELECT '✅ Campo pin_code aggiunto con successo alla tabella users' as status;

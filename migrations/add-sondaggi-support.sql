-- Add support for surveys/polls in communications table

-- Add new column for survey options
ALTER TABLE comunicazioni 
ADD COLUMN IF NOT EXISTS opzioni_sondaggio JSONB DEFAULT NULL;

-- Add column to store survey responses
ALTER TABLE comunicazioni 
ADD COLUMN IF NOT EXISTS risposte_sondaggio JSONB DEFAULT '[]'::jsonb;

-- Structure of opzioni_sondaggio:
-- {
--   "domanda": "Quale giorno preferisci per la riunione?",
--   "opzioni": ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì"],
--   "multipla": false  -- se true, l'utente può selezionare più opzioni
-- }

-- Structure of risposte_sondaggio (array):
-- [
--   {
--     "user_id": "uuid-123",
--     "risposta": ["Lunedì"],  -- array anche se singola per uniformità
--     "timestamp": "2024-01-15T10:30:00Z"
--   }
-- ]

-- Create index for better performance on survey queries
CREATE INDEX IF NOT EXISTS idx_comunicazioni_tipo_sondaggio 
ON comunicazioni(tipo) 
WHERE tipo = 'sondaggio';

-- Comments for documentation
COMMENT ON COLUMN comunicazioni.opzioni_sondaggio IS 'Survey question and options in JSON format';
COMMENT ON COLUMN comunicazioni.risposte_sondaggio IS 'Array of user responses to the survey';

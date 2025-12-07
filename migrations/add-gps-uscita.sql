-- =====================================================
-- AGGIUNGI GPS USCITA
-- =====================================================
-- Aggiunge campo per salvare la posizione GPS dell'uscita
-- separatamente dall'ingresso
-- =====================================================

-- Step 1: Aggiungi colonna posizione_gps_uscita
ALTER TABLE timbrature 
ADD COLUMN IF NOT EXISTS posizione_gps_uscita JSONB;

-- Step 2: Aggiungi anche latitudine/longitudine separate per uscita
ALTER TABLE timbrature
ADD COLUMN IF NOT EXISTS latitudine_uscita DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS longitudine_uscita DECIMAL(11, 8);

-- Step 3: Crea indici per performance
CREATE INDEX IF NOT EXISTS idx_timbrature_gps_uscita ON timbrature USING GIN (posizione_gps_uscita);
CREATE INDEX IF NOT EXISTS idx_timbrature_coords_uscita ON timbrature(latitudine_uscita, longitudine_uscita) WHERE latitudine_uscita IS NOT NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Campo GPS uscita aggiunto!';
    RAISE NOTICE '📍 Ora il sistema salverà la posizione GPS anche per l''uscita';
    RAISE NOTICE '🗺️ Campi aggiunti:';
    RAISE NOTICE '   - posizione_gps_uscita (JSONB)';
    RAISE NOTICE '   - latitudine_uscita (DECIMAL)';
    RAISE NOTICE '   - longitudine_uscita (DECIMAL)';
END $$;

COMMENT ON COLUMN timbrature.posizione_gps_uscita IS 'Posizione GPS dell''uscita (latitude, longitude, indirizzo, accuratezza)';
COMMENT ON COLUMN timbrature.latitudine_uscita IS 'Latitudine GPS uscita (per query geografiche)';
COMMENT ON COLUMN timbrature.longitudine_uscita IS 'Longitudine GPS uscita (per query geografiche)';

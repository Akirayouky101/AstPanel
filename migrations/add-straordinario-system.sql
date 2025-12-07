-- =====================================================
-- SISTEMA CALCOLO STRAORDINARI AUTOMATICO
-- =====================================================
-- Regole:
-- 1. Sabato e Domenica: TUTTO straordinario
-- 2. Feriali fuori orario 08:00-12:00 / 13:00-17:00: straordinario
-- 3. Feriali oltre 8 ore totali: straordinario
-- =====================================================

-- Step 1: Aggiungi colonna ore_straordinario
ALTER TABLE timbrature 
ADD COLUMN IF NOT EXISTS ore_straordinario DECIMAL(5,2) DEFAULT 0;

-- Step 2: Crea function per calcolare ore straordinario
CREATE OR REPLACE FUNCTION calcola_straordinario(
    p_data DATE,
    p_ora_ingresso TIME,
    p_ora_uscita TIME,
    p_pausa_inizio TIME,
    p_pausa_fine TIME
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_giorno_settimana INT;
    v_ore_totali DECIMAL(5,2);
    v_ore_straordinario DECIMAL(5,2) := 0;
    v_pausa_minuti INT := 0;
    v_ora_corrente TIME;
    v_minuti_straordinario INT := 0;
    v_minuti_normali INT := 0;
BEGIN
    -- Se mancano dati, ritorna 0
    IF p_ora_ingresso IS NULL OR p_ora_uscita IS NULL THEN
        RETURN 0;
    END IF;

    -- Giorno settimana (0=domenica, 1=lunedì, ..., 6=sabato)
    v_giorno_settimana := EXTRACT(DOW FROM p_data);
    
    -- Calcola pausa in minuti
    IF p_pausa_inizio IS NOT NULL AND p_pausa_fine IS NOT NULL THEN
        v_pausa_minuti := EXTRACT(EPOCH FROM (p_pausa_fine - p_pausa_inizio)) / 60;
    END IF;
    
    -- Calcola ore totali
    v_ore_totali := (EXTRACT(EPOCH FROM (p_ora_uscita - p_ora_ingresso)) / 3600) - (v_pausa_minuti / 60.0);
    
    -- REGOLA 1: Sabato (6) o Domenica (0) = TUTTO straordinario
    IF v_giorno_settimana = 0 OR v_giorno_settimana = 6 THEN
        RETURN v_ore_totali;
    END IF;
    
    -- REGOLA 2 e 3: Giorni feriali (lun-ven)
    -- Orario normale: 08:00-12:00 e 13:00-17:00 (max 8 ore)
    
    -- Conta minuti straordinario
    v_minuti_straordinario := 0;
    v_minuti_normali := 0;
    
    -- Ciclo da ora_ingresso a ora_uscita (esclusa pausa)
    v_ora_corrente := p_ora_ingresso;
    
    WHILE v_ora_corrente < p_ora_uscita LOOP
        -- Salta se siamo in pausa pranzo
        IF p_pausa_inizio IS NOT NULL AND p_pausa_fine IS NOT NULL AND
           v_ora_corrente >= p_pausa_inizio AND v_ora_corrente < p_pausa_fine THEN
            -- In pausa, salta
            v_ora_corrente := v_ora_corrente + INTERVAL '1 minute';
            CONTINUE;
        END IF;
        
        -- Controlla se è orario normale (08:00-12:00 o 13:00-17:00)
        IF (v_ora_corrente >= '08:00:00'::TIME AND v_ora_corrente < '12:00:00'::TIME) OR
           (v_ora_corrente >= '13:00:00'::TIME AND v_ora_corrente < '17:00:00'::TIME) THEN
            v_minuti_normali := v_minuti_normali + 1;
        ELSE
            v_minuti_straordinario := v_minuti_straordinario + 1;
        END IF;
        
        v_ora_corrente := v_ora_corrente + INTERVAL '1 minute';
    END LOOP;
    
    -- Converti minuti in ore decimali
    v_ore_straordinario := v_minuti_straordinario / 60.0;
    
    -- REGOLA 3: Se le ore normali superano 8, l'eccedenza è straordinario
    IF (v_minuti_normali / 60.0) > 8 THEN
        v_ore_straordinario := v_ore_straordinario + ((v_minuti_normali / 60.0) - 8);
    END IF;
    
    RETURN ROUND(v_ore_straordinario, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 3: Aggiorna function calculate_ore_lavorate per includere straordinari
CREATE OR REPLACE FUNCTION calculate_ore_lavorate()
RETURNS TRIGGER AS $$
DECLARE
    v_pausa_minuti INT := 0;
BEGIN
    -- Calcola pausa in minuti
    IF NEW.pausa_inizio IS NOT NULL AND NEW.pausa_fine IS NOT NULL THEN
        v_pausa_minuti := EXTRACT(EPOCH FROM (NEW.pausa_fine - NEW.pausa_inizio)) / 60;
    END IF;
    
    -- Calcola ore lavorate totali
    IF NEW.ora_ingresso IS NOT NULL AND NEW.ora_uscita IS NOT NULL THEN
        NEW.ore_lavorate := (EXTRACT(EPOCH FROM (NEW.ora_uscita::time - NEW.ora_ingresso::time)) / 3600) - (v_pausa_minuti / 60.0);
    END IF;
    
    -- Calcola ore straordinario
    NEW.ore_straordinario := calcola_straordinario(
        NEW.data,
        NEW.ora_ingresso,
        NEW.ora_uscita,
        NEW.pausa_inizio,
        NEW.pausa_fine
    );
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Ricalcola straordinari per timbrature esistenti
UPDATE timbrature 
SET ore_straordinario = calcola_straordinario(
    data,
    ora_ingresso,
    ora_uscita,
    pausa_inizio,
    pausa_fine
)
WHERE ora_ingresso IS NOT NULL AND ora_uscita IS NOT NULL;

-- Step 5: Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_timbrature_straordinario ON timbrature(ore_straordinario) WHERE ore_straordinario > 0;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Sistema straordinari implementato!';
    RAISE NOTICE '📊 Regole attive:';
    RAISE NOTICE '   - Sabato/Domenica: tutto straordinario';
    RAISE NOTICE '   - Feriali fuori 08:00-12:00/13:00-17:00: straordinario';
    RAISE NOTICE '   - Feriali oltre 8 ore: straordinario';
    RAISE NOTICE '✅ Trigger automatico attivato';
    RAISE NOTICE '✅ Timbrature esistenti ricalcolate';
END $$;

COMMENT ON COLUMN timbrature.ore_straordinario IS 'Ore straordinario calcolate automaticamente - Sab/Dom tutto straordinario, feriali fuori 08:00-12:00/13:00-17:00 o oltre 8h';

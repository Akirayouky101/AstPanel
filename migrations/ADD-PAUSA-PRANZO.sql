-- ================================================
-- AGGIUNGI GESTIONE PAUSA PRANZO PERSONALIZZATA
-- Data: 7 dicembre 2025
-- ================================================

-- STEP 1: Aggiungi campo pausa_pranzo_minuti alla tabella users
-- Ogni dipendente può avere una pausa diversa (30min, 45min, 60min, ecc.)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pausa_pranzo_minuti INTEGER DEFAULT 60;

-- STEP 2: Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_pausa_pranzo 
ON users(pausa_pranzo_minuti);

-- STEP 3: Aggiungi commento descrittivo
COMMENT ON COLUMN users.pausa_pranzo_minuti IS 'Durata pausa pranzo in minuti (es: 30, 45, 60). Se 0 = nessuna pausa automatica';

-- ================================================
-- CONFIGURAZIONE INIZIALE
-- ================================================

-- Imposta pausa standard per tutti (60 minuti = 1 ora)
UPDATE users 
SET pausa_pranzo_minuti = 60 
WHERE pausa_pranzo_minuti IS NULL OR pausa_pranzo_minuti = 0;

-- Esempi personalizzati (decommentare se serve):
-- UPDATE users SET pausa_pranzo_minuti = 30 WHERE email = 'parttime@example.com';  -- Part-time: 30min
-- UPDATE users SET pausa_pranzo_minuti = 45 WHERE ruolo = 'Operaio';               -- Operai: 45min
-- UPDATE users SET pausa_pranzo_minuti = 0 WHERE ruolo = 'Amministratore';         -- Admin: no pausa automatica

-- ================================================
-- STEP 4: Aggiungi campi pausa alla tabella timbrature
-- ================================================

-- Inizio pausa (opzionale, per tracciare pausa effettiva)
ALTER TABLE timbrature 
ADD COLUMN IF NOT EXISTS pausa_inizio TIME;

-- Fine pausa (opzionale)
ALTER TABLE timbrature 
ADD COLUMN IF NOT EXISTS pausa_fine TIME;

-- Minuti di pausa effettivi (calcolato automaticamente)
ALTER TABLE timbrature 
ADD COLUMN IF NOT EXISTS pausa_minuti INTEGER DEFAULT 0;

-- Commenti
COMMENT ON COLUMN timbrature.pausa_inizio IS 'Orario inizio pausa (opzionale, se tracciato)';
COMMENT ON COLUMN timbrature.pausa_fine IS 'Orario fine pausa (opzionale, se tracciato)';
COMMENT ON COLUMN timbrature.pausa_minuti IS 'Minuti di pausa da sottrarre (default: valore da users.pausa_pranzo_minuti)';

-- ================================================
-- STEP 5: Funzione per calcolare ore nette (con pausa)
-- ================================================

CREATE OR REPLACE FUNCTION calcola_ore_nette(
    p_ora_ingresso TIME,
    p_ora_uscita TIME,
    p_pausa_minuti INTEGER DEFAULT 60
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    ore_lorde DECIMAL(10,2);
    ore_nette DECIMAL(10,2);
BEGIN
    -- Calcola ore lorde (senza pausa)
    ore_lorde := EXTRACT(EPOCH FROM (p_ora_uscita - p_ora_ingresso)) / 3600.0;
    
    -- Sottrai pausa in ore (es: 60min = 1h)
    ore_nette := ore_lorde - (p_pausa_minuti / 60.0);
    
    -- Non permettere valori negativi
    IF ore_nette < 0 THEN
        ore_nette := 0;
    END IF;
    
    RETURN ore_nette;
END;
$$;

-- ================================================
-- STEP 6: Trigger per calcolo automatico ore_lavorate CON PAUSA
-- ================================================

CREATE OR REPLACE FUNCTION trigger_calcola_ore_lavorate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    pausa_utente INTEGER;
BEGIN
    -- Se c'è uscita, calcola ore lavorate
    IF NEW.ora_uscita IS NOT NULL THEN
        -- Prendi pausa dell'utente (default 60 se non trovato)
        SELECT COALESCE(pausa_pranzo_minuti, 60) 
        INTO pausa_utente
        FROM users 
        WHERE id = NEW.user_id;
        
        -- Se non è stato specificato pausa_minuti, usa quello dell'utente
        IF NEW.pausa_minuti IS NULL OR NEW.pausa_minuti = 0 THEN
            NEW.pausa_minuti := pausa_utente;
        END IF;
        
        -- Calcola ore nette con pausa
        NEW.ore_lavorate := calcola_ore_nette(
            NEW.ora_ingresso, 
            NEW.ora_uscita, 
            NEW.pausa_minuti
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Ricrea trigger (drop + create)
DROP TRIGGER IF EXISTS trigger_ore_lavorate ON timbrature;

CREATE TRIGGER trigger_ore_lavorate
    BEFORE INSERT OR UPDATE ON timbrature
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcola_ore_lavorate();

-- ================================================
-- VERIFICA
-- ================================================

-- Vedi configurazione pause per tutti gli utenti
SELECT 
    id,
    nome,
    cognome,
    ruolo,
    pausa_pranzo_minuti,
    CASE 
        WHEN pausa_pranzo_minuti = 0 THEN '⏭️ No pausa automatica'
        WHEN pausa_pranzo_minuti = 30 THEN '⏸️ 30 minuti'
        WHEN pausa_pranzo_minuti = 45 THEN '⏸️ 45 minuti'
        WHEN pausa_pranzo_minuti = 60 THEN '⏸️ 1 ora (standard)'
        ELSE '⏸️ ' || pausa_pranzo_minuti || ' minuti'
    END as pausa_descrizione,
    costo_orario
FROM users
ORDER BY pausa_pranzo_minuti DESC;

-- Test calcolo ore nette
SELECT 
    '08:00:00'::TIME as ingresso,
    '17:00:00'::TIME as uscita,
    60 as pausa_minuti,
    calcola_ore_nette('08:00:00'::TIME, '17:00:00'::TIME, 60) as ore_nette,
    '✅ Risultato atteso: 8.00 (9h - 1h pausa)' as note;

-- ================================================
-- RISULTATO ATTESO
-- ================================================
-- users.pausa_pranzo_minuti = 60 (o personalizzato)
-- timbrature con ora_uscita → ore_lavorate calcolato CON sottrazione pausa
-- Esempio: 08:00-17:00 con pausa 60min = 8h nette (non 9h)
-- ================================================

-- ================================================
-- NOTE IMPLEMENTAZIONE FRONTEND
-- ================================================
-- 1. TimbratureService deve considerare pausa_minuti nel calcolo live
-- 2. UI deve mostrare: "Ore Lorde" vs "Ore Nette (con pausa)"
-- 3. Admin può modificare pausa_pranzo_minuti per ogni utente
-- 4. Opzionale: Bottone "Timbra Pausa" per tracciare pausa effettiva
-- ================================================

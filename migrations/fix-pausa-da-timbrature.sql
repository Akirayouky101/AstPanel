-- ================================================
-- FIX: Calcolo pausa basato su pausa_inizio/pausa_fine reali
-- Problema: il trigger usava pausa_pranzo_minuti fisso dell'utente
-- anche quando erano presenti pausa_inizio e pausa_fine dalle timbrature.
-- Fix: priorità a pausa_inizio/pausa_fine, fallback al valore utente.
-- Data: 2026-07-22
-- ================================================

CREATE OR REPLACE FUNCTION trigger_calcola_ore_lavorate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    pausa_utente  INTEGER;
    pausa_effettiva INTEGER;
BEGIN
    IF NEW.ora_uscita IS NOT NULL THEN

        -- Priorità 1: usa pausa_inizio e pausa_fine se entrambi presenti
        IF NEW.pausa_inizio IS NOT NULL AND NEW.pausa_fine IS NOT NULL THEN
            pausa_effettiva := ROUND(
                EXTRACT(EPOCH FROM (NEW.pausa_fine::time - NEW.pausa_inizio::time)) / 60.0
            )::INTEGER;
            NEW.pausa_minuti := pausa_effettiva;

        ELSE
            -- Priorità 2: usa pausa_minuti già impostato sul record
            IF NEW.pausa_minuti IS NOT NULL AND NEW.pausa_minuti > 0 THEN
                pausa_effettiva := NEW.pausa_minuti;
            ELSE
                -- Priorità 3: fallback al valore di default dell'utente
                SELECT COALESCE(pausa_pranzo_minuti, 60)
                INTO pausa_utente
                FROM users
                WHERE id = NEW.user_id;

                pausa_effettiva := pausa_utente;
                NEW.pausa_minuti := pausa_effettiva;
            END IF;
        END IF;

        -- Calcola ore nette sottraendo la pausa effettiva
        NEW.ore_lavorate := calcola_ore_nette(
            NEW.ora_ingresso,
            NEW.ora_uscita,
            pausa_effettiva
        );

    END IF;

    RETURN NEW;
END;
$$;

-- Il trigger esiste già, viene aggiornata solo la funzione
-- (DROP + CREATE non necessario perché usiamo CREATE OR REPLACE sulla funzione)

-- ================================================
-- RICALCOLA le timbrature già presenti che hanno
-- pausa_inizio e pausa_fine ma pausa_minuti errata
-- ================================================
UPDATE timbrature
SET
    pausa_minuti = ROUND(
        EXTRACT(EPOCH FROM (pausa_fine::time - pausa_inizio::time)) / 60.0
    )::INTEGER,
    ore_lavorate = calcola_ore_nette(
        ora_ingresso,
        ora_uscita,
        ROUND(EXTRACT(EPOCH FROM (pausa_fine::time - pausa_inizio::time)) / 60.0)::INTEGER
    )
WHERE
    pausa_inizio IS NOT NULL
    AND pausa_fine IS NOT NULL
    AND ora_uscita IS NOT NULL
    AND (
        -- pausa_minuti non corrisponde alla differenza reale
        pausa_minuti IS DISTINCT FROM ROUND(
            EXTRACT(EPOCH FROM (pausa_fine::time - pausa_inizio::time)) / 60.0
        )::INTEGER
    );

-- ============================================
-- FIX: Correggi riferimenti tasks.codice_lavorazione → tasks.titolo
-- ============================================
-- La tabella tasks NON ha colonna "codice_lavorazione", ha solo "titolo"
-- Questo script aggiorna i trigger per usare il campo corretto

-- ============================================
-- 1. FIX TRIGGER: Trasferimento impegno a lavorazione
-- ============================================
CREATE OR REPLACE FUNCTION trasferisci_impegno_a_lavorazione()
RETURNS TRIGGER AS $$
BEGIN
    -- Se lavorazione creata da preventivo
    IF NEW.preventivo_id IS NOT NULL THEN
        
        -- Trasferisci impegni da preventivo a lavorazione
        UPDATE impegni_magazzino
        SET 
            lavorazione_id = NEW.id,
            tipo_impegno = 'lavorazione',
            note = note || ' → Trasferito a lavorazione ' || NEW.titolo
        WHERE preventivo_id = NEW.preventivo_id 
        AND stato = 'attivo';
        
        RAISE NOTICE '🔄 Impegni trasferiti da preventivo a lavorazione %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ricrea trigger
DROP TRIGGER IF EXISTS trigger_trasferisci_impegno ON tasks;
CREATE TRIGGER trigger_trasferisci_impegno
    AFTER INSERT ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION trasferisci_impegno_a_lavorazione();

-- ============================================
-- 2. FIX TRIGGER: Completamento lavorazione
-- ============================================
CREATE OR REPLACE FUNCTION completa_lavorazione_con_impegno()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_impegno RECORD;
BEGIN
    -- Solo se lavorazione completata
    IF NEW.stato = 'completato' AND (OLD.stato IS NULL OR OLD.stato != 'completato') THEN
        
        SELECT id INTO v_user_id FROM users WHERE auth_id = NEW.assigned_user_id;
        
        -- Per ogni impegno attivo
        FOR v_impegno IN 
            SELECT * FROM impegni_magazzino 
            WHERE lavorazione_id = NEW.id AND stato = 'attivo'
        LOOP
            -- Scala giacenza fisica
            UPDATE components
            SET quantita_disponibile = quantita_disponibile - v_impegno.quantita_impegnata
            WHERE id = v_impegno.prodotto_id;
            
            -- Registra movimento
            INSERT INTO movimenti_magazzino (
                prodotto_id,
                tipo_movimento,
                quantita,
                giacenza_prima,
                giacenza_dopo,
                causale,
                data_movimento,
                created_by
            )
            SELECT 
                v_impegno.prodotto_id,
                'uscita',
                -v_impegno.quantita_impegnata,
                c.quantita_disponibile + v_impegno.quantita_impegnata,
                c.quantita_disponibile,
                'Completamento lavorazione: ' || NEW.titolo,
                NOW(),
                v_user_id
            FROM components c WHERE c.id = v_impegno.prodotto_id;
            
            -- Marca impegno come completato
            UPDATE impegni_magazzino
            SET 
                stato = 'completato',
                completed_at = NOW()
            WHERE id = v_impegno.id;
        END LOOP;
        
        RAISE NOTICE '✅ Scalata giacenza per lavorazione completata: %', NEW.titolo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop vecchio trigger se esiste
DROP TRIGGER IF EXISTS trigger_scarica_componenti ON tasks;
DROP TRIGGER IF EXISTS trigger_completa_lavorazione_con_impegno ON tasks;

-- Crea nuovo trigger
CREATE TRIGGER trigger_completa_lavorazione_con_impegno
    AFTER UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION completa_lavorazione_con_impegno();

-- ============================================
-- FINE FIX
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Fix colonne tasks (titolo invece di codice_lavorazione) completato!';
END $$;

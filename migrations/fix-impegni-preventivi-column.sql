-- ============================================
-- FIX: Correggi riferimenti colonna preventivi
-- ============================================
-- La tabella preventivi ha colonna "numero" non "numero_preventivo"
-- Questo script aggiorna i trigger per usare il nome corretto

-- ============================================
-- 1. FIX TRIGGER: Impegno preventivo
-- ============================================
CREATE OR REPLACE FUNCTION impegna_prodotti_preventivo()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_item RECORD;
BEGIN
    -- Solo se preventivo passa a 'accettato'
    IF NEW.stato = 'accettato' AND (OLD.stato IS NULL OR OLD.stato != 'accettato') THEN
        
        -- Trova user_id da auth_id
        SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
        
        -- Impegna tutti i prodotti del preventivo
        FOR v_item IN 
            SELECT prodotto_id, quantita 
            FROM preventivo_items 
            WHERE preventivo_id = NEW.id
        LOOP
            INSERT INTO impegni_magazzino (
                prodotto_id,
                quantita_impegnata,
                tipo_impegno,
                preventivo_id,
                stato,
                created_by,
                note
            ) VALUES (
                v_item.prodotto_id,
                v_item.quantita,
                'preventivo',
                NEW.id,
                'attivo',
                v_user_id,
                'Impegno automatico per preventivo ' || NEW.numero
            );
        END LOOP;
        
        RAISE NOTICE '✅ Impegnati prodotti per preventivo %', NEW.numero;
    END IF;
    
    -- Se preventivo viene annullato o rifiutato, libera impegni
    IF NEW.stato IN ('annullato', 'rifiutato') AND OLD.stato = 'accettato' THEN
        UPDATE impegni_magazzino
        SET stato = 'annullato'
        WHERE preventivo_id = NEW.id AND stato = 'attivo';
        
        RAISE NOTICE '🔓 Liberati prodotti per preventivo annullato %', NEW.numero;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea trigger
DROP TRIGGER IF EXISTS trigger_impegna_preventivo ON preventivi;
CREATE TRIGGER trigger_impegna_preventivo
    AFTER UPDATE ON preventivi
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_preventivo();

-- ============================================
-- FINE FIX
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Fix colonna preventivi.numero completato!';
END $$;

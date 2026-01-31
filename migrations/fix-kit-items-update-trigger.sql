-- ============================================
-- TRIGGER PER AGGIORNAMENTO QUANTITA' KIT_ITEMS
-- ============================================
-- Quando si aggiorna la quantità di un componente nel kit,
-- aggiorna anche l'impegno corrispondente

CREATE OR REPLACE FUNCTION update_impegno_on_kit_item_update()
RETURNS TRIGGER AS $$
DECLARE
    v_differenza DECIMAL(10,2);
    v_kit_codice VARCHAR(50);
    v_prodotto_nome VARCHAR(255);
BEGIN
    -- Solo se cambia la quantità
    IF OLD.quantita != NEW.quantita THEN
        v_differenza := NEW.quantita - OLD.quantita;
        
        SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = NEW.kit_id;
        SELECT nome INTO v_prodotto_nome FROM components WHERE id = NEW.prodotto_id;
        
        -- Aggiorna impegno esistente
        UPDATE impegni_magazzino
        SET quantita_impegnata = NEW.quantita
        WHERE kit_id = NEW.kit_id 
          AND prodotto_id = NEW.prodotto_id 
          AND stato = 'attivo';
        
        -- Registra movimento se aumenta la quantità (maggiore impegno)
        IF v_differenza > 0 THEN
            INSERT INTO movimenti_magazzino (
                prodotto_id, tipo_movimento, quantita, created_by, causale
            ) VALUES (
                NEW.prodotto_id, 
                'scarico', 
                -v_differenza, 
                NEW.aggiunto_da,
                'Quantità aumentata in kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT) || 
                ' (' || COALESCE(v_prodotto_nome, 'prodotto') || ': +' || v_differenza || ' unità)'
            );
        -- Se diminuisce la quantità (libera impegno)
        ELSIF v_differenza < 0 THEN
            INSERT INTO movimenti_magazzino (
                prodotto_id, tipo_movimento, quantita, created_by, causale
            ) VALUES (
                NEW.prodotto_id, 
                'reintegro', 
                ABS(v_differenza), 
                NEW.aggiunto_da,
                'Quantità ridotta in kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT) || 
                ' (' || COALESCE(v_prodotto_nome, 'prodotto') || ': -' || ABS(v_differenza) || ' unità reintegrate)'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Rimuovi trigger se esiste
DROP TRIGGER IF EXISTS trigger_update_impegno_kit ON kit_items;

-- Crea trigger
CREATE TRIGGER trigger_update_impegno_kit
    AFTER UPDATE ON kit_items
    FOR EACH ROW
    WHEN (OLD.quantita IS DISTINCT FROM NEW.quantita)
    EXECUTE FUNCTION update_impegno_on_kit_item_update();

-- ============================================
-- VERIFICA
-- ============================================
SELECT '✅ Trigger update_impegno_on_kit_item_update creato!' AS status;

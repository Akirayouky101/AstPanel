-- ============================================
-- RIPRISTINA TRIGGER ORIGINALI FUNZIONANTI
-- ============================================
-- Ripristina i trigger che gestivano correttamente gli impegni kit

-- ============================================
-- TRIGGER: Impegna prodotti quando aggiungi componente a kit
-- ============================================
CREATE OR REPLACE FUNCTION impegna_prodotti_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_existing_impegno UUID;
    v_old_quantita DECIMAL(10,2);
BEGIN
    -- Trova user_id (usa il creator se disponibile, altrimenti auth.uid())
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    
    -- Prendi codice kit per la nota
    SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = NEW.kit_id;
    
    -- Verifica se esiste già un impegno attivo per questo prodotto e kit
    SELECT id, quantita_impegnata INTO v_existing_impegno, v_old_quantita
    FROM impegni_magazzino
    WHERE kit_id = NEW.kit_id 
    AND prodotto_id = NEW.prodotto_id
    AND stato = 'attivo'
    LIMIT 1;
    
    IF v_existing_impegno IS NOT NULL THEN
        -- Aggiorna quantità esistente invece di creare nuova riga
        UPDATE impegni_magazzino
        SET quantita_impegnata = quantita_impegnata + NEW.quantita,
            note = 'Impegno automatico per kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT) || 
                   ' (aggiornato da ' || v_old_quantita || ' a ' || (v_old_quantita + NEW.quantita) || ')'
        WHERE id = v_existing_impegno;
    ELSE
        -- Crea nuovo impegno
        INSERT INTO impegni_magazzino (
            prodotto_id,
            quantita_impegnata,
            tipo_impegno,
            kit_id,
            stato,
            created_by,
            note
        ) VALUES (
            NEW.prodotto_id,
            NEW.quantita,
            'kit',
            NEW.kit_id,
            'attivo',
            v_user_id,
            'Impegno automatico per kit ' || COALESCE(v_kit_codice, NEW.kit_id::TEXT)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop e ricrea trigger
DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items;

CREATE TRIGGER trigger_impegna_kit
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_kit();

-- ============================================
-- TRIGGER: Libera impegni quando elimini componente da kit
-- ============================================
CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_codice VARCHAR(50);
    v_prodotto_nome VARCHAR(255);
    v_quantita_liberata DECIMAL(10,2);
BEGIN
    -- Prendi info per storico
    SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = OLD.kit_id;
    SELECT nome INTO v_prodotto_nome FROM components WHERE id = OLD.prodotto_id;
    
    -- Trova quantità che verrà liberata
    SELECT quantita_impegnata INTO v_quantita_liberata
    FROM impegni_magazzino
    WHERE kit_id = OLD.kit_id 
    AND prodotto_id = OLD.prodotto_id
    AND stato = 'attivo'
    LIMIT 1;
    
    -- Annulla impegno per questo componente
    UPDATE impegni_magazzino
    SET 
        stato = 'annullato',
        completed_at = NOW()
    WHERE kit_id = OLD.kit_id 
    AND prodotto_id = OLD.prodotto_id
    AND stato = 'attivo';
    
    -- Registra storico movimento (usa OLD.aggiunto_da come created_by)
    IF v_quantita_liberata IS NOT NULL AND v_quantita_liberata > 0 THEN
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            created_by,
            causale
        ) VALUES (
            OLD.prodotto_id,
            'reintegro',
            v_quantita_liberata,
            OLD.aggiunto_da,  -- USA L'UTENTE CHE HA AGGIUNTO IL COMPONENTE
            'Componente rimosso da kit ' || COALESCE(v_kit_codice, OLD.kit_id::TEXT) || 
            ' (' || COALESCE(v_prodotto_nome, 'prodotto') || ': ' || v_quantita_liberata || ' unità reintegrate)'
        );
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Drop e ricrea trigger
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;

CREATE TRIGGER trigger_libera_impegno_kit
    AFTER DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

-- ============================================
-- TRIGGER: Libera impegni quando elimini intero kit
-- ============================================
CREATE OR REPLACE FUNCTION libera_impegni_kit_eliminato()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_codice VARCHAR(50);
    v_componente RECORD;
    v_user_deleting UUID;
BEGIN
    v_kit_codice := OLD.codice_kit;
    
    -- Usa deleted_by se disponibile, altrimenti created_by del kit
    v_user_deleting := COALESCE(OLD.deleted_by, OLD.created_by);
    
    -- Per ogni componente con impegno attivo
    FOR v_componente IN 
        SELECT 
            im.prodotto_id,
            im.quantita_impegnata,
            c.nome as prodotto_nome
        FROM impegni_magazzino im
        JOIN components c ON c.id = im.prodotto_id
        WHERE im.kit_id = OLD.id 
        AND im.stato = 'attivo'
    LOOP
        -- Annulla impegno
        UPDATE impegni_magazzino
        SET 
            stato = 'annullato',
            completed_at = NOW()
        WHERE kit_id = OLD.id 
        AND prodotto_id = v_componente.prodotto_id
        AND stato = 'attivo';
        
        -- Registra movimento singolo per ogni prodotto
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            created_by,
            causale
        ) VALUES (
            v_componente.prodotto_id,
            'reintegro',
            v_componente.quantita_impegnata,
            v_user_deleting,  -- USA deleted_by o created_by del kit
            'Kit eliminato: ' || COALESCE(v_kit_codice, OLD.id::TEXT) || 
            ' (' || COALESCE(v_componente.prodotto_nome, 'prodotto') || ': ' || 
            v_componente.quantita_impegnata || ' unità reintegrate)'
        );
    END LOOP;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Drop e ricrea trigger
DROP TRIGGER IF EXISTS trigger_libera_impegni_kit_eliminato ON kits;

CREATE TRIGGER trigger_libera_impegni_kit_eliminato
    BEFORE DELETE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegni_kit_eliminato();

-- Verifica trigger ripristinati
SELECT '✅ Trigger originali ripristinati!' AS status;

SELECT tgname AS trigger_name, proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'kit_items'::regclass
AND NOT tgisinternal;

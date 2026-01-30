-- ============================================
-- AGGIUNGI IMPEGNI AUTOMATICI PER KIT
-- ============================================
-- Quando crei un kit e aggiungi componenti, impegna automaticamente i prodotti
-- fino alla consegna del kit

-- ============================================
-- TRIGGER: Impegna prodotti quando aggiungi componente a kit
-- ============================================
CREATE OR REPLACE FUNCTION impegna_prodotti_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
BEGIN
    -- Trova user_id (usa il creator se disponibile, altrimenti auth.uid())
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    
    -- Prendi codice kit per la nota
    SELECT codice_kit INTO v_kit_codice FROM kits WHERE id = NEW.kit_id;
    
    -- Crea impegno per questo componente del kit
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
    
    RAISE NOTICE '🔒 Impegnati %.2f unità di prodotto per kit %', NEW.quantita, v_kit_codice;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger se esiste
DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items;

-- Crea trigger AFTER INSERT (dopo che il componente è stato aggiunto)
CREATE TRIGGER trigger_impegna_kit
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_kit();

-- ============================================
-- TRIGGER: Libera impegni quando elimini componente da kit
-- ============================================
CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- Annulla impegno per questo componente
    UPDATE impegni_magazzino
    SET 
        stato = 'annullato',
        completed_at = NOW()
    WHERE kit_id = OLD.kit_id 
    AND prodotto_id = OLD.prodotto_id
    AND stato = 'attivo';
    
    RAISE NOTICE '🔓 Liberato impegno per componente rimosso da kit';
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger se esiste
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;

-- Crea trigger AFTER DELETE
CREATE TRIGGER trigger_libera_impegno_kit
    AFTER DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

-- ============================================
-- TRIGGER: Completa impegni quando kit viene consegnato/completato
-- ============================================
-- Assumo che nella tabella kits ci sia un campo "stato" o simile
-- Se non esiste, dovrai aggiungere questa logica quando consegni il kit

CREATE OR REPLACE FUNCTION completa_impegni_kit()
RETURNS TRIGGER AS $$
BEGIN
    -- Se il kit passa a stato "consegnato" o "completato"
    IF NEW.stato IN ('consegnato', 'completato', 'chiuso') AND 
       (OLD.stato IS NULL OR OLD.stato NOT IN ('consegnato', 'completato', 'chiuso')) THEN
        
        -- Completa tutti gli impegni attivi per questo kit
        UPDATE impegni_magazzino
        SET 
            stato = 'completato',
            completed_at = NOW()
        WHERE kit_id = NEW.id 
        AND stato = 'attivo';
        
        RAISE NOTICE '✅ Completati impegni per kit consegnato %', NEW.codice_kit;
        
        -- OPZIONALE: Scala anche la giacenza fisica se necessario
        -- (commenta questa parte se la giacenza viene scalata in altro modo)
        /*
        FOR v_item IN 
            SELECT prodotto_id, quantita_impegnata
            FROM impegni_magazzino
            WHERE kit_id = NEW.id AND stato = 'completato'
        LOOP
            UPDATE components
            SET quantita_disponibile = quantita_disponibile - v_item.quantita_impegnata
            WHERE id = v_item.prodotto_id;
        END LOOP;
        */
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger se esiste
DROP TRIGGER IF EXISTS trigger_completa_kit ON kits;

-- Crea trigger solo se la tabella kits ha il campo "stato"
-- NOTA: Se la tabella kits NON ha campo "stato", questo trigger darà errore
-- In quel caso, commentalo o adatta la logica
CREATE TRIGGER trigger_completa_kit
    AFTER UPDATE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION completa_impegni_kit();

-- ============================================
-- FINE MIGRATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Trigger impegni kit creati con successo!';
    RAISE NOTICE '🔒 I componenti kit ora vengono impegnati automaticamente';
    RAISE NOTICE '🔓 Impegni liberati quando elimini componenti';
    RAISE NOTICE '✅ Impegni completati quando consegni il kit';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NOTA: Se tabella kits non ha campo "stato", commenta trigger_completa_kit';
END $$;

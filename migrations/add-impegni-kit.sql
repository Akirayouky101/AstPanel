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
        
        RAISE NOTICE '🔒 Aggiornato impegno per kit %: %.2f → %.2f', v_kit_codice, v_old_quantita, (v_old_quantita + NEW.quantita);
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
        
        RAISE NOTICE '🔒 Impegnati %.2f unità di prodotto per kit %', NEW.quantita, v_kit_codice;
    END IF;
    
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
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_prodotto_nome VARCHAR(255);
    v_quantita_liberata DECIMAL(10,2);
BEGIN
    -- Trova user_id
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    
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
    
    -- Registra storico movimento
    IF v_quantita_liberata IS NOT NULL AND v_quantita_liberata > 0 THEN
        INSERT INTO movimenti_magazzino (
            prodotto_id,
            tipo_movimento,
            quantita,
            created_by,
            note
        ) VALUES (
            OLD.prodotto_id,
            'reintegro',
            v_quantita_liberata,
            v_user_id,
            'Componente rimosso da kit ' || COALESCE(v_kit_codice, OLD.kit_id::TEXT) || 
            ' - Materiale reintegrato: ' || v_quantita_liberata || ' unità di ' || COALESCE(v_prodotto_nome, 'prodotto')
        );
        
        RAISE NOTICE '🔓 Liberato impegno per componente rimosso da kit % (%.2f unità)', v_kit_codice, v_quantita_liberata;
    END IF;
    
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
-- TRIGGER: Libera impegni quando elimini intero kit
-- ============================================
CREATE OR REPLACE FUNCTION libera_impegni_kit_eliminato()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_kit_codice VARCHAR(50);
    v_componente RECORD;
    v_totale_reintegrato DECIMAL(10,2) := 0;
BEGIN
    -- Trova user_id
    SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
    
    v_kit_codice := OLD.codice_kit;
    
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
            note
        ) VALUES (
            v_componente.prodotto_id,
            'reintegro',
            v_componente.quantita_impegnata,
            v_user_id,
            'Kit eliminato: ' || COALESCE(v_kit_codice, OLD.id::TEXT) || 
            ' - Materiale reintegrato: ' || v_componente.quantita_impegnata || 
            ' unità di ' || COALESCE(v_componente.prodotto_nome, 'prodotto')
        );
        
        v_totale_reintegrato := v_totale_reintegrato + v_componente.quantita_impegnata;
    END LOOP;
    
    IF v_totale_reintegrato > 0 THEN
        RAISE NOTICE '🗑️ Kit % eliminato - Reintegrati componenti per un totale di %.2f unità', v_kit_codice, v_totale_reintegrato;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger se esiste
DROP TRIGGER IF EXISTS trigger_libera_kit_eliminato ON kits;

-- Crea trigger BEFORE DELETE (prima che il kit venga eliminato)
CREATE TRIGGER trigger_libera_kit_eliminato
    BEFORE DELETE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegni_kit_eliminato();

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
    RAISE NOTICE '';
    RAISE NOTICE 'FUNZIONALITÀ IMPLEMENTATE:';
    RAISE NOTICE '🔒 Componenti kit impegnati automaticamente quando aggiungi al kit';
    RAISE NOTICE '📊 Stesso prodotto aggiunto più volte → quantità sommate (no righe duplicate)';
    RAISE NOTICE '🔓 Impegni liberati quando rimuovi componenti dal kit';
    RAISE NOTICE '�️ Impegni liberati quando elimini intero kit';
    RAISE NOTICE '📝 Storico movimenti_magazzino registrato per ogni reintegro';
    RAISE NOTICE '✅ Impegni completati quando consegni il kit (stato → consegnato)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NOTA: Se tabella kits non ha campo "stato", commenta trigger_completa_kit';
END $$;

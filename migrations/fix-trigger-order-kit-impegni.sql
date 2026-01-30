-- ============================================
-- FIX: Ordine trigger kit impegni
-- ============================================
-- PROBLEMA: Il trigger di verifica giacenza e quello di creazione impegno
-- sono entrambi BEFORE INSERT, quindi PostgreSQL li esegue in ordine alfabetico.
-- Questo causa che l'impegno venga creato PRIMA della verifica, lasciando
-- righe orfane in kit_items senza impegni corrispondenti.
--
-- SOLUZIONE: 
-- 1. Verifica giacenza resta BEFORE INSERT (blocca prima dell'inserimento)
-- 2. Creazione impegno diventa AFTER INSERT (solo se inserimento riuscito)
-- ============================================

-- Drop del trigger esistente (creazione impegno)
DROP TRIGGER IF EXISTS trigger_impegna_kit ON kit_items CASCADE;

-- Ricrea la funzione (identica, ma verrà chiamata AFTER)
CREATE OR REPLACE FUNCTION impegna_prodotti_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
    v_existing_impegno UUID;
    v_existing_qty DECIMAL(10,2);
    v_user_id UUID;
BEGIN
    -- Recupera codice kit per riferimento
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = NEW.kit_id;

    -- Recupera user_id dalla tabella users usando auth.uid()
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_id = auth.uid();

    -- Verifica se esiste già un impegno per questo prodotto in questo kit
    SELECT id, quantita_impegnata 
    INTO v_existing_impegno, v_existing_qty
    FROM impegni_magazzino
    WHERE prodotto_id = NEW.prodotto_id
      AND kit_id = NEW.kit_id
      AND stato = 'attivo';

    IF v_existing_impegno IS NOT NULL THEN
        -- Aggiorna la quantità dell'impegno esistente (NO DUPLICATI)
        UPDATE impegni_magazzino
        SET quantita_impegnata = v_existing_qty + NEW.quantita,
            note = COALESCE(note, '') || ' | Aggiunta quantità: ' || NEW.quantita || ' (totale: ' || (v_existing_qty + NEW.quantita) || ')'
        WHERE id = v_existing_impegno;
        
        RAISE NOTICE 'Aggiornato impegno esistente per prodotto % nel kit %: da % a %', 
            NEW.prodotto_nome, v_kit_code, v_existing_qty, (v_existing_qty + NEW.quantita);
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
            COALESCE(v_user_id, '00000000-0000-0000-0000-000000000001'),
            'Impegno automatico per kit ' || v_kit_code
        );
        
        RAISE NOTICE 'Creato impegno per prodotto % nel kit %: quantità %', 
            NEW.prodotto_nome, v_kit_code, NEW.quantita;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ricrea il trigger come AFTER INSERT invece di BEFORE INSERT
CREATE TRIGGER trigger_impegna_kit
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION impegna_prodotti_kit();

-- ============================================
-- VERIFICA: Il trigger di verifica giacenza è già BEFORE INSERT
-- (non serve modificarlo, è già corretto)
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ FIX ORDINE TRIGGER COMPLETATO';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'ORDINE ESECUZIONE CORRETTO:';
    RAISE NOTICE '1️⃣  BEFORE INSERT: trigger_verifica_giacenza_libera_kit';
    RAISE NOTICE '    → Verifica giacenza libera disponibile';
    RAISE NOTICE '    → Se insufficiente, BLOCCA inserimento con RAISE EXCEPTION';
    RAISE NOTICE '';
    RAISE NOTICE '2️⃣  INSERT eseguito (solo se verifica passata)';
    RAISE NOTICE '    → Riga inserita in kit_items';
    RAISE NOTICE '';
    RAISE NOTICE '3️⃣  AFTER INSERT: trigger_impegna_kit';
    RAISE NOTICE '    → Crea/aggiorna impegno in impegni_magazzino';
    RAISE NOTICE '    → Eseguito SOLO se INSERT riuscito';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '🎯 Ora non ci saranno più righe orfane in kit_items!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;

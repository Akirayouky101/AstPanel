-- ============================================
-- TRIGGER: Eliminazione Kit con Pulizia Completa
-- ============================================
-- Quando elimini un kit, questo trigger:
-- 1. Cancella tutti gli impegni collegati al kit
-- 2. Registra lo storico in movimenti_magazzino (reintegro)
-- 3. Libera la giacenza per tutti i componenti
-- ============================================

-- Funzione per liberare impegni quando elimini UN componente dal kit
CREATE OR REPLACE FUNCTION libera_impegno_kit()
RETURNS TRIGGER AS $$
DECLARE
    v_kit_code TEXT;
    v_user_id UUID;
BEGIN
    -- Recupera codice kit
    SELECT codice_kit INTO v_kit_code
    FROM kits
    WHERE id = OLD.kit_id;

    -- Recupera user_id
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_id = auth.uid();

    -- Cancella l'impegno
    UPDATE impegni_magazzino
    SET stato = 'annullato',
        completed_at = NOW(),
        note = COALESCE(note, '') || ' | Componente rimosso dal kit ' || v_kit_code
    WHERE prodotto_id = OLD.prodotto_id
      AND kit_id = OLD.kit_id
      AND stato = 'attivo';

    -- Registra lo storico del reintegro
    INSERT INTO movimenti_magazzino (
        prodotto_id,
        tipo_movimento,
        quantita,
        causale,
        created_by
    ) VALUES (
        OLD.prodotto_id,
        'reintegro',
        OLD.quantita,
        'Componente rimosso da kit ' || v_kit_code || ' - Prodotto: ' || OLD.prodotto_nome,
        COALESCE(v_user_id, '00000000-0000-0000-0000-000000000001')
    );

    RAISE NOTICE 'Liberato impegno per % (qtà: %) dal kit %', 
        OLD.prodotto_nome, OLD.quantita, v_kit_code;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger su DELETE componente singolo
DROP TRIGGER IF EXISTS trigger_libera_impegno_kit ON kit_items;
CREATE TRIGGER trigger_libera_impegno_kit
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegno_kit();

-- ============================================
-- Funzione per liberare TUTTI gli impegni quando elimini IL KIT INTERO
-- ============================================
CREATE OR REPLACE FUNCTION libera_impegni_kit_eliminato()
RETURNS TRIGGER AS $$
DECLARE
    v_component RECORD;
    v_user_id UUID;
    v_count INTEGER := 0;
BEGIN
    -- Recupera user_id
    SELECT id INTO v_user_id
    FROM users
    WHERE auth_id = auth.uid();

    -- Per ogni componente del kit
    FOR v_component IN 
        SELECT 
            ki.prodotto_id,
            ki.prodotto_nome,
            ki.quantita,
            i.id as impegno_id,
            i.quantita_impegnata
        FROM kit_items ki
        LEFT JOIN impegni_magazzino i ON i.prodotto_id = ki.prodotto_id 
            AND i.kit_id = ki.kit_id 
            AND i.stato = 'attivo'
        WHERE ki.kit_id = OLD.id
    LOOP
        -- Se esiste un impegno, annullalo
        IF v_component.impegno_id IS NOT NULL THEN
            UPDATE impegni_magazzino
            SET stato = 'annullato',
                completed_at = NOW(),
                note = COALESCE(note, '') || ' | Kit eliminato: ' || OLD.codice_kit
            WHERE id = v_component.impegno_id;

            -- Registra lo storico
            INSERT INTO movimenti_magazzino (
                prodotto_id,
                tipo_movimento,
                quantita,
                causale,
                created_by
            ) VALUES (
                v_component.prodotto_id,
                'reintegro',
                v_component.quantita_impegnata,
                'Kit eliminato: ' || OLD.codice_kit || ' - Prodotto: ' || v_component.prodotto_nome || ' reintegrato (' || v_component.quantita_impegnata || ' pz)',
                COALESCE(v_user_id, '00000000-0000-0000-0000-000000000001')
            );

            v_count := v_count + 1;
            
            RAISE NOTICE 'Reintegrato % (qtà: %) da kit eliminato %', 
                v_component.prodotto_nome, v_component.quantita_impegnata, OLD.codice_kit;
        END IF;
    END LOOP;

    RAISE NOTICE 'Kit % eliminato: liberati % impegni totali', OLD.codice_kit, v_count;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger su DELETE kit intero
DROP TRIGGER IF EXISTS trigger_libera_kit_eliminato ON kits;
CREATE TRIGGER trigger_libera_kit_eliminato
    BEFORE DELETE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION libera_impegni_kit_eliminato();

-- ============================================
-- RIEPILOGO
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ TRIGGER ELIMINAZIONE KIT INSTALLATI';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'COMPORTAMENTO:';
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  Quando RIMUOVI UN COMPONENTE dal kit:';
    RAISE NOTICE '   → Annulla impegno specifico';
    RAISE NOTICE '   → Registra reintegro in movimenti_magazzino';
    RAISE NOTICE '   → Libera giacenza del prodotto';
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  Quando ELIMINI IL KIT INTERO:';
    RAISE NOTICE '   → Annulla TUTTI gli impegni del kit';
    RAISE NOTICE '   → Registra reintegro per ogni componente';
    RAISE NOTICE '   → Libera giacenza di tutti i prodotti';
    RAISE NOTICE '   → Pulizia completa - nessuna traccia rimane';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '🎯 Sistema pronto per test!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;

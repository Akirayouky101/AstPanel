-- ============================================
-- PULIZIA RIGHE ORFANE KIT
-- ============================================
-- Questo script elimina:
-- 1. Componenti kit senza impegni corrispondenti
-- 2. Impegni kit senza componenti corrispondenti
-- ============================================

DO $$
DECLARE
    v_orfani_items INTEGER := 0;
    v_orfani_impegni INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 Ricerca righe orfane...';
    RAISE NOTICE '';

    -- 1. Trova componenti kit senza impegno
    SELECT COUNT(*) INTO v_orfani_items
    FROM kit_items ki
    LEFT JOIN impegni_magazzino i ON i.prodotto_id = ki.prodotto_id 
        AND i.kit_id = ki.kit_id 
        AND i.stato = 'attivo'
    WHERE i.id IS NULL;

    IF v_orfani_items > 0 THEN
        RAISE NOTICE '⚠️  Trovati % componenti kit senza impegno', v_orfani_items;
        
        -- Elimina componenti orfani
        DELETE FROM kit_items ki
        WHERE NOT EXISTS (
            SELECT 1 FROM impegni_magazzino i
            WHERE i.prodotto_id = ki.prodotto_id 
              AND i.kit_id = ki.kit_id 
              AND i.stato = 'attivo'
        );
        
        RAISE NOTICE '✅ Eliminati % componenti orfani', v_orfani_items;
    ELSE
        RAISE NOTICE '✅ Nessun componente orfano trovato';
    END IF;

    RAISE NOTICE '';

    -- 2. Trova impegni kit senza componente
    SELECT COUNT(*) INTO v_orfani_impegni
    FROM impegni_magazzino i
    LEFT JOIN kit_items ki ON ki.prodotto_id = i.prodotto_id 
        AND ki.kit_id = i.kit_id
    WHERE i.tipo_impegno = 'kit'
      AND i.stato = 'attivo'
      AND ki.id IS NULL;

    IF v_orfani_impegni > 0 THEN
        RAISE NOTICE '⚠️  Trovati % impegni kit senza componente', v_orfani_impegni;
        
        -- Annulla impegni orfani
        UPDATE impegni_magazzino i
        SET stato = 'annullato',
            completed_at = NOW(),
            note = COALESCE(note, '') || ' | Impegno orfano - pulizia automatica'
        WHERE i.tipo_impegno = 'kit'
          AND i.stato = 'attivo'
          AND NOT EXISTS (
              SELECT 1 FROM kit_items ki
              WHERE ki.prodotto_id = i.prodotto_id 
                AND ki.kit_id = i.kit_id
          );
        
        RAISE NOTICE '✅ Annullati % impegni orfani', v_orfani_impegni;
    ELSE
        RAISE NOTICE '✅ Nessun impegno orfano trovato';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ PULIZIA COMPLETATA';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'Righe orfane eliminate:';
    RAISE NOTICE '  - Componenti kit: %', v_orfani_items;
    RAISE NOTICE '  - Impegni: %', v_orfani_impegni;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;

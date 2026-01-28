-- =====================================================
-- MIGRAZIONE: Rimuovi prezzo_vendita da components
-- Data: 28 gennaio 2026
-- Descrizione: Il prezzo vendita non ha senso nel magazzino
--              perché varia per ogni preventivo con ricarico %
--              Manteniamo solo prezzo_acquisto (esente IVA)
-- =====================================================

-- 1. RIMUOVI COLONNA SE ESISTE
-- =====================================================

DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'components' 
        AND column_name = 'prezzo_vendita'
    ) THEN
        ALTER TABLE components DROP COLUMN prezzo_vendita;
        RAISE NOTICE '✅ Colonna prezzo_vendita rimossa da components';
    ELSE
        RAISE NOTICE 'ℹ️  Colonna prezzo_vendita non esistente (già rimossa)';
    END IF;
END $$;


-- 2. VERIFICA FINALE
-- =====================================================

DO $$ 
DECLARE
    has_prezzo_vendita BOOLEAN;
    has_prezzo_acquisto BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'components' AND column_name = 'prezzo_vendita'
    ) INTO has_prezzo_vendita;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'components' AND column_name = 'prezzo_acquisto'
    ) INTO has_prezzo_acquisto;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ VERIFICA MIGRAZIONE PREZZI';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    
    IF has_prezzo_vendita THEN
        RAISE NOTICE '❌ prezzo_vendita: ANCORA PRESENTE (errore!)';
    ELSE
        RAISE NOTICE '✅ prezzo_vendita: RIMOSSO';
    END IF;
    
    IF has_prezzo_acquisto THEN
        RAISE NOTICE '✅ prezzo_acquisto: PRESENTE (esente IVA)';
    ELSE
        RAISE NOTICE '❌ prezzo_acquisto: MANCANTE (errore!)';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 LOGICA PREZZI:';
    RAISE NOTICE '  • Magazzino: solo prezzo_acquisto (esente IVA)';
    RAISE NOTICE '  • Preventivo: calcola ricarico %% sul prezzo_acquisto';
    RAISE NOTICE '  • Ogni preventivo può avere ricarico diverso';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $$;

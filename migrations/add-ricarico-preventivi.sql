-- =====================================================
-- MIGRAZIONE: Aggiungi ricarico % ai preventivi
-- Data: 28 gennaio 2026
-- Descrizione: Aggiunge campi per tracciare costo acquisto
--              e ricarico percentuale nelle righe preventivo
-- =====================================================

-- 1. AGGIUNGI COLONNE A PREVENTIVI_ITEMS
-- =====================================================

-- Prezzo acquisto (dal magazzino, esente IVA)
ALTER TABLE preventivi_items 
ADD COLUMN IF NOT EXISTS prezzo_acquisto DECIMAL(10,2) DEFAULT 0;

-- Ricarico percentuale applicato
ALTER TABLE preventivi_items 
ADD COLUMN IF NOT EXISTS ricarico_percentuale DECIMAL(5,2) DEFAULT 0;

-- 2. COMMENTI ESPLICATIVI
-- =====================================================

COMMENT ON COLUMN preventivi_items.prezzo_acquisto IS 'Costo acquisto dal magazzino (esente IVA)';
COMMENT ON COLUMN preventivi_items.ricarico_percentuale IS 'Percentuale di ricarico applicata sul prezzo_acquisto';
COMMENT ON COLUMN preventivi_items.prezzo_unitario IS 'Prezzo vendita = prezzo_acquisto * (1 + ricarico_percentuale/100)';

-- 3. SINCRONIZZA DATI ESISTENTI
-- =====================================================

-- Per i preventivi già esistenti, imposta prezzo_acquisto = prezzo_unitario (come fallback)
UPDATE preventivi_items 
SET prezzo_acquisto = prezzo_unitario
WHERE prezzo_acquisto = 0 OR prezzo_acquisto IS NULL;

-- 4. VERIFICA FINALE
-- =====================================================

DO $$ 
DECLARE
    col_count INTEGER;
    items_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_name = 'preventivi_items'
    AND column_name IN ('prezzo_acquisto', 'ricarico_percentuale');
    
    SELECT COUNT(*) INTO items_count
    FROM preventivi_items;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ MIGRAZIONE RICARICO COMPLETATA';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Colonne aggiunte: %', col_count;
    RAISE NOTICE '';
    RAISE NOTICE '📋 Nuovi campi in preventivi_items:';
    RAISE NOTICE '  ✅ prezzo_acquisto - Costo dal magazzino (esente IVA)';
    RAISE NOTICE '  ✅ ricarico_percentuale - Ricarico %% applicato';
    RAISE NOTICE '';
    RAISE NOTICE '💰 LOGICA CALCOLO PREZZI:';
    RAISE NOTICE '  1. Prezzo acquisto (dal magazzino)';
    RAISE NOTICE '  2. + Ricarico %% (es: 30%%)';
    RAISE NOTICE '  3. = Prezzo vendita (prezzo_unitario)';
    RAISE NOTICE '  4. - Sconto %% (se presente)';
    RAISE NOTICE '  5. = Importo riga';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Righe preventivi aggiornate: %', items_count;
    RAISE NOTICE '========================================';
END $$;

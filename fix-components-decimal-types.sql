-- 🔧 FIX TIPI DI DATO TABELLA COMPONENTS
-- Converte campi numerici da INTEGER a DECIMAL(10,2)
-- STEP 1: Drop vista che dipende da components
-- STEP 2: Converti colonne INTEGER a DECIMAL
-- STEP 3: Ricrea vista

-- ========================================
-- STEP 1: DROP VISTA
-- ========================================
DROP VIEW IF EXISTS v_giacenze_complete CASCADE;

DO $$
BEGIN
    RAISE NOTICE '✅ Vista v_giacenze_complete droppata';
END $$;

-- ========================================
-- STEP 2: CONVERTI COLONNE INTEGER → DECIMAL
-- ========================================
DO $$
BEGIN
    -- quantita_disponibile (INTEGER → DECIMAL)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'components' 
        AND column_name = 'quantita_disponibile' 
        AND data_type = 'integer'
    ) THEN
        ALTER TABLE components 
        ALTER COLUMN quantita_disponibile TYPE DECIMAL(10,2);
        RAISE NOTICE '✅ quantita_disponibile convertito a DECIMAL(10,2)';
    END IF;

    -- quantita_magazzino (INTEGER → DECIMAL)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'components' 
        AND column_name = 'quantita_magazzino' 
        AND data_type = 'integer'
    ) THEN
        ALTER TABLE components 
        ALTER COLUMN quantita_magazzino TYPE DECIMAL(10,2);
        RAISE NOTICE '✅ quantita_magazzino convertito a DECIMAL(10,2)';
    END IF;

    -- quantita_minima (INTEGER → DECIMAL)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'components' 
        AND column_name = 'quantita_minima' 
        AND data_type = 'integer'
    ) THEN
        ALTER TABLE components 
        ALTER COLUMN quantita_minima TYPE DECIMAL(10,2);
        RAISE NOTICE '✅ quantita_minima convertito a DECIMAL(10,2)';
    END IF;

    RAISE NOTICE '🎯 Conversione colonne completata!';
END $$;

-- ========================================
-- STEP 3: RICREA VISTA v_giacenze_complete
-- ========================================
CREATE OR REPLACE VIEW v_giacenze_complete AS
SELECT 
    c.id,
    c.codice,
    c.nome,
    c.categoria,
    c.descrizione,
    c.unita_misura,
    c.um,
    c.barcode,
    c.qr_code_data,
    c.prezzo_acquisto,
    c.prezzo_unitario,
    c.fornitore_id,
    f.ragione_sociale as fornitore_nome,
    c.stato,
    
    -- Giacenza fisica (quantita_disponibile)
    COALESCE(c.quantita_disponibile, 0) as giacenza_fisica,
    
    -- Giacenza impegnata (somma impegni attivi)
    COALESCE(
        (SELECT SUM(quantita_impegnata) 
         FROM impegni_magazzino 
         WHERE prodotto_id = c.id 
         AND stato = 'attivo'), 
        0
    ) as giacenza_impegnata,
    
    -- Giacenza libera (fisica - impegnata)
    COALESCE(c.quantita_disponibile, 0) - COALESCE(
        (SELECT SUM(quantita_impegnata) 
         FROM impegni_magazzino 
         WHERE prodotto_id = c.id 
         AND stato = 'attivo'), 
        0
    ) as giacenza_libera,
    
    -- Giacenza minima
    COALESCE(c.giacenza_minima, 0) as giacenza_minima,
    
    -- Stato giacenza
    CASE 
        WHEN (COALESCE(c.quantita_disponibile, 0) - COALESCE(
            (SELECT SUM(quantita_impegnata) 
             FROM impegni_magazzino 
             WHERE prodotto_id = c.id 
             AND stato = 'attivo'), 
            0
        )) <= 0 THEN 'esaurito'
        WHEN (COALESCE(c.quantita_disponibile, 0) - COALESCE(
            (SELECT SUM(quantita_impegnata) 
             FROM impegni_magazzino 
             WHERE prodotto_id = c.id 
             AND stato = 'attivo'), 
            0
        )) <= COALESCE(c.giacenza_minima, 0) THEN 'basso'
        ELSE 'ok'
    END as stato_giacenza,
    
    c.created_at,
    c.updated_at,
    c.deleted_at,
    c.deleted_by
    
FROM components c
LEFT JOIN fornitori f ON f.id = c.fornitore_id
WHERE c.deleted_at IS NULL;

DO $$
BEGIN
    RAISE NOTICE '✅ Vista v_giacenze_complete ricreata con successo!';
    RAISE NOTICE '🎯 FIX COMPLETATO!';
END $$;


-- ========================================
-- VERIFICA FINALE
-- ========================================
SELECT 
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
FROM information_schema.columns
WHERE table_name = 'components'
AND column_name IN (
    'quantita_disponibile', 
    'quantita_magazzino', 
    'quantita_minima',
    'prezzo_acquisto',
    'prezzo_unitario',
    'giacenza',
    'giacenza_minima'
)
ORDER BY column_name;

-- Test vista
SELECT COUNT(*) as prodotti_totali FROM v_giacenze_complete;

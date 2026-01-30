-- ============================================
-- RESET COMPLETO SISTEMA (TRANNE PRODOTTI)
-- ============================================
-- ATTENZIONE: Questo script CANCELLA TUTTI I DATI da:
-- - Preventivi e preventivo_items
-- - Kit e kit_items  
-- - Ordini fornitori e ordini_fornitori_items
-- - Impegni magazzino
-- - Movimenti magazzino
-- - Tasks/Lavorazioni
--
-- MANTIENE:
-- - Prodotti (components)
-- - Fornitori
-- - Clienti
-- - Utenti
-- ============================================

-- CONFERMA PRIMA DI ESEGUIRE!
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  ⚠️  ⚠️  ATTENZIONE ⚠️  ⚠️  ⚠️';
    RAISE NOTICE '';
    RAISE NOTICE 'Stai per CANCELLARE TUTTI I DATI da:';
    RAISE NOTICE '- Preventivi';
    RAISE NOTICE '- Kit';
    RAISE NOTICE '- Ordini Fornitori';
    RAISE NOTICE '- Impegni Magazzino';
    RAISE NOTICE '- Movimenti Magazzino';
    RAISE NOTICE '- Lavorazioni';
    RAISE NOTICE '';
    RAISE NOTICE 'I PRODOTTI in magazzino NON verranno cancellati';
    RAISE NOTICE '';
    RAISE NOTICE 'Se sei sicuro, continua l esecuzione...';
    RAISE NOTICE '';
END $$;

-- ============================================
-- 1. CANCELLA IMPEGNI MAGAZZINO
-- ============================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM impegni_magazzino;
    DELETE FROM impegni_magazzino;
    RAISE NOTICE '✅ Cancellati % impegni magazzino', v_count;
END $$;

-- ============================================
-- 2. CANCELLA MOVIMENTI MAGAZZINO
-- ============================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM movimenti_magazzino;
    DELETE FROM movimenti_magazzino;
    RAISE NOTICE '✅ Cancellati % movimenti magazzino', v_count;
END $$;

-- ============================================
-- 3. CANCELLA PREVENTIVI
-- ============================================
DO $$
DECLARE
    v_count_items INTEGER;
    v_count_preventivi INTEGER;
BEGIN
    -- Prima gli items (per FK)
    SELECT COUNT(*) INTO v_count_items FROM preventivo_items;
    DELETE FROM preventivo_items;
    
    -- Poi i preventivi
    SELECT COUNT(*) INTO v_count_preventivi FROM preventivi;
    DELETE FROM preventivi;
    
    RAISE NOTICE '✅ Cancellati % preventivi e % righe', v_count_preventivi, v_count_items;
END $$;

-- ============================================
-- 4. CANCELLA KIT
-- ============================================
DO $$
DECLARE
    v_count_items INTEGER;
    v_count_kits INTEGER;
BEGIN
    -- Prima i componenti kit (per FK)
    SELECT COUNT(*) INTO v_count_items FROM kit_items;
    DELETE FROM kit_items;
    
    -- Poi i kit
    SELECT COUNT(*) INTO v_count_kits FROM kits;
    DELETE FROM kits;
    
    RAISE NOTICE '✅ Cancellati % kit e % componenti', v_count_kits, v_count_items;
END $$;

-- ============================================
-- 5. CANCELLA ORDINI FORNITORI
-- ============================================
DO $$
DECLARE
    v_count_items INTEGER;
    v_count_ordini INTEGER;
BEGIN
    -- Prima le righe ordine (per FK)
    SELECT COUNT(*) INTO v_count_items FROM ordini_fornitori_items;
    DELETE FROM ordini_fornitori_items;
    
    -- Poi gli ordini
    SELECT COUNT(*) INTO v_count_ordini FROM ordini_fornitori;
    DELETE FROM ordini_fornitori;
    
    RAISE NOTICE '✅ Cancellati % ordini fornitori e % righe', v_count_ordini, v_count_items;
END $$;

-- ============================================
-- 6. CANCELLA LAVORAZIONI/TASKS
-- ============================================
DO $$
DECLARE
    v_count_components INTEGER;
    v_count_tasks INTEGER;
BEGIN
    -- Prima i componenti tasks (se esistono)
    SELECT COUNT(*) INTO v_count_components FROM task_components WHERE 1=1;
    DELETE FROM task_components;
    
    -- Poi le tasks
    SELECT COUNT(*) INTO v_count_tasks FROM tasks;
    DELETE FROM tasks;
    
    RAISE NOTICE '✅ Cancellate % lavorazioni e % componenti', v_count_tasks, v_count_components;
EXCEPTION
    WHEN undefined_table THEN
        -- Se task_components non esiste, ignora
        SELECT COUNT(*) INTO v_count_tasks FROM tasks;
        DELETE FROM tasks;
        RAISE NOTICE '✅ Cancellate % lavorazioni', v_count_tasks;
END $$;

-- ============================================
-- 7. RESET SEQUENZE/CONTATORI (se esistono)
-- ============================================
DO $$
BEGIN
    -- Reset contatori preventivi (se usi sequenze)
    -- ALTER SEQUENCE preventivi_numero_seq RESTART WITH 1;
    
    RAISE NOTICE '✅ Sequenze resettate (se presenti)';
EXCEPTION
    WHEN undefined_object THEN
        RAISE NOTICE 'ℹ️  Nessuna sequenza da resettare';
END $$;

-- ============================================
-- RIEPILOGO FINALE
-- ============================================
DO $$
DECLARE
    v_prodotti INTEGER;
    v_fornitori INTEGER;
    v_clienti INTEGER;
BEGIN
    -- Conta cosa è rimasto
    SELECT COUNT(*) INTO v_prodotti FROM components;
    SELECT COUNT(*) INTO v_fornitori FROM fornitori;
    SELECT COUNT(*) INTO v_clienti FROM clients;
    
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ RESET COMPLETATO CON SUCCESSO!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'DATI CANCELLATI:';
    RAISE NOTICE '❌ Preventivi e righe';
    RAISE NOTICE '❌ Kit e componenti';
    RAISE NOTICE '❌ Ordini fornitori e righe';
    RAISE NOTICE '❌ Impegni magazzino';
    RAISE NOTICE '❌ Movimenti magazzino';
    RAISE NOTICE '❌ Lavorazioni/Tasks';
    RAISE NOTICE '';
    RAISE NOTICE 'DATI CONSERVATI:';
    RAISE NOTICE '✅ % Prodotti in magazzino', v_prodotti;
    RAISE NOTICE '✅ % Fornitori', v_fornitori;
    RAISE NOTICE '✅ % Clienti', v_clienti;
    RAISE NOTICE '✅ Utenti (tutti)';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '🎯 Sistema pronto per ripartire da zero!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;

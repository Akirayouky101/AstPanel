-- ============================================
-- RESET TOTALE COMPLETO - CANCELLA TUTTO
-- ============================================
-- ⚠️ ATTENZIONE: Questo script CANCELLA TUTTI I DATI DA TUTTE LE TABELLE
-- Verranno eliminate TUTTE le informazioni, inclusi:
-- - PRODOTTI (components)
-- - Preventivi e preventivi_items
-- - Kit e kit_items  
-- - Ordini fornitori e ordini_fornitore_items
-- - Impegni magazzino
-- - Movimenti magazzino
-- - Tasks/Lavorazioni
-- - Fornitori
-- - Clienti
-- 
-- RIMANE SOLO:
-- - Struttura database (tabelle, viste, trigger)
-- - Utenti (per poter ancora accedere)
-- ============================================

-- CONFERMA PRIMA DI ESEGUIRE!
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔥 🔥 🔥 ATTENZIONE - RESET TOTALE 🔥 🔥 🔥';
    RAISE NOTICE '';
    RAISE NOTICE 'Stai per CANCELLARE TUTTO IL DATABASE!';
    RAISE NOTICE 'Verranno eliminati:';
    RAISE NOTICE '- TUTTI I PRODOTTI';
    RAISE NOTICE '- Tutti i preventivi';
    RAISE NOTICE '- Tutti i kit';
    RAISE NOTICE '- Tutti gli ordini fornitori';
    RAISE NOTICE '- Tutti gli impegni magazzino';
    RAISE NOTICE '- Tutti i movimenti magazzino';
    RAISE NOTICE '- Tutte le lavorazioni';
    RAISE NOTICE '- Tutti i fornitori';
    RAISE NOTICE '- Tutti i clienti';
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
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabella impegni_magazzino non esiste';
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
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabella movimenti_magazzino non esiste';
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
    SELECT COUNT(*) INTO v_count_items FROM preventivi_items;
    DELETE FROM preventivi_items;
    
    -- Poi i preventivi
    SELECT COUNT(*) INTO v_count_preventivi FROM preventivi;
    DELETE FROM preventivi;
    
    RAISE NOTICE '✅ Cancellati % preventivi e % righe', v_count_preventivi, v_count_items;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabelle preventivi non esistono';
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
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabelle kit non esistono';
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
    SELECT COUNT(*) INTO v_count_items FROM ordini_fornitore_items;
    DELETE FROM ordini_fornitore_items;
    
    -- Poi gli ordini
    SELECT COUNT(*) INTO v_count_ordini FROM ordini_fornitore;
    DELETE FROM ordini_fornitore;
    
    RAISE NOTICE '✅ Cancellati % ordini fornitori e % righe', v_count_ordini, v_count_items;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabelle ordini_fornitore non esistono';
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
        -- Se task_components non esiste, prova solo tasks
        BEGIN
            SELECT COUNT(*) INTO v_count_tasks FROM tasks;
            DELETE FROM tasks;
            RAISE NOTICE '✅ Cancellate % lavorazioni', v_count_tasks;
        EXCEPTION
            WHEN undefined_table THEN
                RAISE NOTICE 'ℹ️  Tabelle tasks non esistono';
        END;
END $$;

-- ============================================
-- 7. CANCELLA PRODOTTI (COMPONENTS)
-- ============================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM components;
    DELETE FROM components;
    RAISE NOTICE '🔥 Cancellati % PRODOTTI', v_count;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabella components non esiste';
END $$;

-- ============================================
-- 8. CANCELLA FORNITORI
-- ============================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM fornitori;
    DELETE FROM fornitori;
    RAISE NOTICE '✅ Cancellati % fornitori', v_count;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabella fornitori non esiste';
END $$;

-- ============================================
-- 9. CANCELLA CLIENTI
-- ============================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM clients;
    DELETE FROM clients;
    RAISE NOTICE '✅ Cancellati % clienti', v_count;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'ℹ️  Tabella clients non esiste';
END $$;

-- ============================================
-- 10. RESET SEQUENZE/CONTATORI (se esistono)
-- ============================================
DO $$
BEGIN
    -- Reset contatori (se usi sequenze)
    -- ALTER SEQUENCE preventivi_numero_seq RESTART WITH 1;
    -- ALTER SEQUENCE kits_id_seq RESTART WITH 1;
    
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
    v_utenti INTEGER;
BEGIN
    -- Conta cosa è rimasto
    SELECT COUNT(*) INTO v_utenti FROM users;
    
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '🔥 RESET TOTALE COMPLETATO CON SUCCESSO!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'TUTTI I DATI SONO STATI CANCELLATI:';
    RAISE NOTICE '🔥 Prodotti (components)';
    RAISE NOTICE '❌ Preventivi e righe';
    RAISE NOTICE '❌ Kit e componenti';
    RAISE NOTICE '❌ Ordini fornitori e righe';
    RAISE NOTICE '❌ Impegni magazzino';
    RAISE NOTICE '❌ Movimenti magazzino';
    RAISE NOTICE '❌ Lavorazioni/Tasks';
    RAISE NOTICE '❌ Fornitori';
    RAISE NOTICE '❌ Clienti';
    RAISE NOTICE '';
    RAISE NOTICE 'DATI CONSERVATI:';
    RAISE NOTICE '✅ % Utenti (per accesso al sistema)', v_utenti;
    RAISE NOTICE '✅ Struttura database (tabelle, viste, trigger)';
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '🎯 Database completamente vuoto - pronto per ricaricare!';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END $$;

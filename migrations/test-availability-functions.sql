-- ================================================
-- TEST AVAILABILITY FUNCTIONS
-- Esegui questo DOPO aver eseguito add-availability-system.sql
-- ================================================

-- 1. Verifica che la tabella esista
SELECT COUNT(*) as user_availability_exists 
FROM information_schema.tables 
WHERE table_name = 'user_availability';

-- 2. Verifica che le funzioni esistano
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'calcola_carico_lavoro',
    'trova_dipendente_disponibile',
    'get_dashboard_disponibilita',
    'check_urgenza_veloce'
);

-- 3. Test funzione dashboard (dovrebbe restituire tutti gli utenti dipendenti/admin)
SELECT * FROM get_dashboard_disponibilita();

-- 4. Test check veloce (dovrebbe restituire 1 utente)
SELECT * FROM check_urgenza_veloce();

-- 5. Verifica i permessi
SELECT 
    p.proname as function_name,
    pg_catalog.pg_get_userbyid(p.proowner) as owner,
    p.prosecdef as security_definer
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
AND p.proname IN (
    'calcola_carico_lavoro',
    'trova_dipendente_disponibile',
    'get_dashboard_disponibilita',
    'check_urgenza_veloce'
);

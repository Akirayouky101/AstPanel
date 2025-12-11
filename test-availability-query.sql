-- Test query per debug availability calculation
-- Esegui questo su Supabase SQL Editor per vedere cosa sta succedendo

-- 1. Verifica utenti esistenti
SELECT 
    id,
    nome,
    cognome,
    email,
    ruolo
FROM users
WHERE ruolo IN ('dipendente', 'admin')
ORDER BY cognome, nome;

-- 2. Verifica task attivi per ogni utente (assigned_user_id)
SELECT 
    u.nome || ' ' || u.cognome as utente,
    t.id as task_id,
    t.titolo,
    t.stato,
    t.ore_stimate,
    t.data_inizio,
    t.scadenza
FROM users u
LEFT JOIN tasks t ON t.assigned_user_id = u.id 
    AND t.stato NOT IN ('completata', 'annullata')
WHERE u.ruolo IN ('dipendente', 'admin')
ORDER BY u.cognome, t.id;

-- 3. Verifica task_assignments (multi-user)
SELECT 
    u.nome || ' ' || u.cognome as utente,
    ta.task_id,
    t2.titolo,
    t2.stato,
    ta.ore_assegnate,
    ta.ruolo_assegnazione
FROM users u
LEFT JOIN task_assignments ta ON ta.user_id = u.id
LEFT JOIN tasks t2 ON ta.task_id = t2.id 
    AND t2.stato NOT IN ('completata', 'annullata')
WHERE u.ruolo IN ('dipendente', 'admin')
ORDER BY u.cognome, ta.task_id;

-- 4. Test della funzione aggiornata
SELECT * FROM get_dashboard_disponibilita();

-- 5. Test check urgenza veloce
SELECT * FROM check_urgenza_veloce();

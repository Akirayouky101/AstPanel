-- DEBUG SEMPLICE - Cosa c'è nel database?

-- QUERY 1: Quanti utenti ci sono?
SELECT COUNT(*) as totale_utenti FROM users;

-- QUERY 2: Quali ruoli hanno?
SELECT ruolo, COUNT(*) FROM users GROUP BY ruolo;

-- QUERY 3: Utenti con ruoli che dovrebbero apparire
SELECT 
    id,
    nome,
    cognome,
    email,
    ruolo
FROM users
WHERE ruolo IN ('dipendente', 'admin', 'titolare', 'tecnico', 'segreteria');

-- QUERY 4: Quanti task ci sono?
SELECT COUNT(*) as totale_tasks FROM tasks;

-- QUERY 5: Quanti task ATTIVI ci sono?
SELECT stato, COUNT(*) 
FROM tasks 
GROUP BY stato;

-- QUERY 6: Test DIRETTO della nuova funzione
SELECT * FROM get_dashboard_disponibilita();

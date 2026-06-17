-- DEBUG: Controlla ore calcolate per Raoul Aguirre
-- Esegui su Supabase SQL Editor

-- 1. Trova l'id di Aguirre
SELECT id, nome, cognome, ruolo, stato
FROM users
WHERE cognome ILIKE '%Aguirre%' OR nome ILIKE '%Raoul%';

-- 2. Task assegnati direttamente (assigned_user_id)
SELECT
    t.id,
    t.titolo,
    t.stato,
    t.ore_stimate,
    t.assigned_user_id
FROM tasks t
JOIN users u ON t.assigned_user_id = u.id
WHERE (u.cognome ILIKE '%Aguirre%' OR u.nome ILIKE '%Raoul%')
  AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato');

-- 3. Task assegnati via task_assignments
SELECT
    t.id,
    t.titolo,
    t.stato,
    t.ore_stimate,
    ta.ore_assegnate,
    COALESCE(ta.ore_assegnate, t.ore_stimate, 0) as ore_effettive
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
JOIN users u ON ta.user_id = u.id
WHERE (u.cognome ILIKE '%Aguirre%' OR u.nome ILIKE '%Raoul%')
  AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato');

-- 4. Tutti i task_assignments di Aguirre (anche completati, per vedere se ce ne sono)
SELECT
    t.id,
    t.titolo,
    t.stato,
    t.ore_stimate,
    ta.ore_assegnate
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
JOIN users u ON ta.user_id = u.id
WHERE (u.cognome ILIKE '%Aguirre%' OR u.nome ILIKE '%Raoul%');

-- 5. Risultato finale della funzione per Aguirre
SELECT *
FROM get_dashboard_disponibilita()
WHERE nome_completo ILIKE '%Aguirre%';

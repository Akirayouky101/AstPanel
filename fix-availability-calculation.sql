-- ================================================
-- FIX: Availability Calculation Bug
-- Data: Dicembre 2024
-- Descrizione: Corregge calcolo ore disponibili includendo task_assignments
-- ================================================

-- BUG: La funzione contava solo task nella prossima settimana con date specifiche
-- FIX: Conta TUTTI i task attivi (in_corso, da_fare) + task_assignments multi-user

-- Drop della funzione esistente per evitare conflitti
DROP FUNCTION IF EXISTS get_dashboard_disponibilita();

-- Ricrea la funzione con la logica corretta
CREATE OR REPLACE FUNCTION get_dashboard_disponibilita()
RETURNS TABLE(
    user_id UUID,
    nome_completo TEXT,
    email VARCHAR,
    ruolo VARCHAR,
    task_attivi BIGINT,
    ore_impegnate DECIMAL,
    ore_disponibili DECIMAL,
    stato_disponibilita TEXT,
    priorita INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH 
    -- Ore da task diretti (assigned_user_id)
    ore_dirette AS (
        SELECT 
            u.id as user_id,
            COUNT(t.id) as task_count,
            COALESCE(SUM(t.ore_stimate), 0) as ore_totali
        FROM users u
        LEFT JOIN tasks t ON t.assigned_user_id = u.id 
            AND t.stato NOT IN ('completata', 'annullata')
        WHERE u.ruolo IN ('Dipendente', 'Titolare', 'Tecnico', 'Segreteria')
        GROUP BY u.id
    ),
    -- Ore da task multi-user (task_assignments)
    ore_multiuser AS (
        SELECT 
            u.id as user_id,
            COUNT(ta.task_id) as task_count,
            COALESCE(SUM(ta.ore_assegnate), 0) as ore_totali
        FROM users u
        LEFT JOIN task_assignments ta ON ta.user_id = u.id
        LEFT JOIN tasks t ON ta.task_id = t.id 
            AND t.stato NOT IN ('completata', 'annullata')
        WHERE u.ruolo IN ('Dipendente', 'Titolare', 'Tecnico', 'Segreteria')
        GROUP BY u.id
    ),
    -- Combina tutto
    carico_corrente AS (
        SELECT 
            u.id,
            (u.nome || ' ' || u.cognome) as nome_completo,
            u.email,
            u.ruolo,
            (COALESCE(od.task_count, 0) + COALESCE(om.task_count, 0)) as task_attivi,
            (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali, 0)) as ore_impegnate,
            (40 - (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali, 0))) as ore_disponibili,
            CASE 
                WHEN (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali, 0)) >= 40 THEN 'occupato'
                WHEN (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali, 0)) >= 30 THEN 'quasi_pieno'
                WHEN (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali, 0)) >= 15 THEN 'disponibile'
                ELSE 'molto_disponibile'
            END as stato_disponibilita,
            -- Priorità ruolo: Dipendente > Titolare > Tecnico > Segreteria
            CASE u.ruolo
                WHEN 'Dipendente' THEN 4
                WHEN 'Titolare' THEN 3
                WHEN 'Tecnico' THEN 2
                WHEN 'Segreteria' THEN 1
                ELSE 0
            END as prio_ruolo
        FROM users u
        LEFT JOIN ore_dirette od ON od.user_id = u.id
        LEFT JOIN ore_multiuser om ON om.user_id = u.id
        WHERE u.ruolo IN ('Dipendente', 'Titolare', 'Tecnico', 'Segreteria')
    )
    SELECT 
        cc.id,
        cc.nome_completo::TEXT,
        cc.email,
        cc.ruolo,
        cc.task_attivi,
        cc.ore_impegnate::DECIMAL,
        cc.ore_disponibili::DECIMAL,
        cc.stato_disponibilita::TEXT,
        CASE cc.stato_disponibilita
            WHEN 'molto_disponibile' THEN 4
            WHEN 'disponibile' THEN 3
            WHEN 'quasi_pieno' THEN 2
            WHEN 'occupato' THEN 1
        END as priorita
    FROM carico_corrente cc
    ORDER BY cc.prio_ruolo DESC, priorita DESC, cc.ore_disponibili DESC;
END;
$$ LANGUAGE plpgsql;

-- Verifica che la funzione sia stata aggiornata
SELECT 'Funzione get_dashboard_disponibilita() aggiornata con successo!' as status;

-- ================================================
-- UPDATE: Cambia ordine priorità ruoli
-- Dipendente > Titolare > Tecnico > Segreteria
-- ================================================

-- DROP solo delle funzioni
DROP FUNCTION IF EXISTS get_dashboard_disponibilita();
DROP FUNCTION IF EXISTS trova_dipendente_disponibile(DATE, DATE, DECIMAL, VARCHAR);

-- Ricrea get_dashboard_disponibilita con nuovo ordine priorità
CREATE FUNCTION get_dashboard_disponibilita()
RETURNS TABLE(
    user_id UUID,
    nome_completo TEXT,
    email VARCHAR,
    ruolo VARCHAR,
    task_attivi BIGINT,
    ore_impegnate DECIMAL,
    ore_disponibili DECIMAL,
    stato_disponibilita TEXT,
    priorita INTEGER,
    priorita_ruolo INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH next_week AS (
        SELECT 
            CURRENT_DATE as data_inizio,
            CURRENT_DATE + INTERVAL '7 days' as data_fine
    ),
    carico_corrente AS (
        SELECT 
            u.id,
            (u.nome || ' ' || u.cognome) as nome_completo,
            u.email,
            u.ruolo,
            COUNT(t.id) as task_attivi,
            COALESCE(SUM(t.ore_stimate), 0) as ore_impegnate,
            (40 - COALESCE(SUM(t.ore_stimate), 0)) as ore_disponibili,
            CASE 
                WHEN COALESCE(SUM(t.ore_stimate), 0) >= 40 THEN 'occupato'
                WHEN COALESCE(SUM(t.ore_stimate), 0) >= 30 THEN 'quasi_pieno'
                WHEN COALESCE(SUM(t.ore_stimate), 0) >= 15 THEN 'disponibile'
                ELSE 'molto_disponibile'
            END as stato_disponibilita,
            CASE u.ruolo
                WHEN 'Dipendente' THEN 4
                WHEN 'Titolare' THEN 3
                WHEN 'Tecnico' THEN 2
                WHEN 'Segreteria' THEN 1
                ELSE 0
            END as prio_ruolo
        FROM users u
        CROSS JOIN next_week nw
        LEFT JOIN tasks t ON t.assigned_user_id = u.id 
            AND t.stato NOT IN ('completata', 'annullata')
            AND (
                (t.scadenza >= nw.data_inizio AND t.scadenza <= nw.data_fine)
                OR (t.data_inizio >= nw.data_inizio AND t.data_inizio <= nw.data_fine)
            )
        GROUP BY u.id, u.nome, u.cognome, u.email, u.ruolo
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
        END as priorita,
        cc.prio_ruolo::INTEGER as priorita_ruolo
    FROM carico_corrente cc
    ORDER BY cc.prio_ruolo DESC, priorita DESC, cc.ore_disponibili DESC;
END;
$$ LANGUAGE plpgsql;

-- Ricrea trova_dipendente_disponibile con nuovo ordine
CREATE FUNCTION trova_dipendente_disponibile(
    p_data_inizio DATE,
    p_data_fine DATE,
    p_ore_necessarie DECIMAL DEFAULT 8,
    p_ruolo VARCHAR DEFAULT NULL
) RETURNS TABLE(
    user_id UUID,
    nome_completo TEXT,
    email VARCHAR,
    ruolo VARCHAR,
    task_attivi INTEGER,
    ore_impegnate DECIMAL,
    ore_disponibili DECIMAL,
    percentuale_disponibilita INTEGER,
    score INTEGER,
    priorita_ruolo INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH carico_utenti AS (
        SELECT 
            u.id,
            (u.nome || ' ' || u.cognome) as nome_completo,
            u.email,
            u.ruolo,
            COUNT(t.id) as task_count,
            COALESCE(SUM(t.ore_stimate), 0) as ore_task,
            (40 - COALESCE(SUM(t.ore_stimate), 0)) as ore_libere,
            (100 - LEAST(100, (COALESCE(SUM(t.ore_stimate), 0) / 40 * 100))) as disponibilita,
            CASE u.ruolo
                WHEN 'Dipendente' THEN 4
                WHEN 'Titolare' THEN 3
                WHEN 'Tecnico' THEN 2
                WHEN 'Segreteria' THEN 1
                ELSE 0
            END as prio_ruolo
        FROM users u
        LEFT JOIN tasks t ON t.assigned_user_id = u.id 
            AND t.stato NOT IN ('completata', 'annullata')
            AND (
                (t.scadenza >= p_data_inizio AND t.scadenza <= p_data_fine)
                OR (t.data_inizio >= p_data_inizio AND t.data_inizio <= p_data_fine)
            )
        WHERE (p_ruolo IS NULL OR u.ruolo = p_ruolo)
        GROUP BY u.id, u.nome, u.cognome, u.email, u.ruolo
    ),
    availability_check AS (
        SELECT 
            cu.*,
            CASE 
                WHEN cu.ore_libere >= p_ore_necessarie THEN 100
                WHEN cu.ore_libere > 0 THEN (cu.ore_libere / p_ore_necessarie * 100)
                ELSE 0
            END as score_disponibilita
        FROM carico_utenti cu
    )
    SELECT 
        ac.id,
        ac.nome_completo::TEXT,
        ac.email,
        ac.ruolo,
        ac.task_count::INTEGER,
        ac.ore_task::DECIMAL,
        ac.ore_libere::DECIMAL,
        ac.disponibilita::INTEGER,
        ac.score_disponibilita::INTEGER,
        ac.prio_ruolo::INTEGER
    FROM availability_check ac
    ORDER BY ac.prio_ruolo DESC, ac.score_disponibilita DESC, ac.task_count ASC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Permissions
ALTER FUNCTION get_dashboard_disponibilita() OWNER TO postgres;
ALTER FUNCTION trova_dipendente_disponibile(DATE, DATE, DECIMAL, VARCHAR) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION get_dashboard_disponibilita() TO authenticated;
GRANT EXECUTE ON FUNCTION trova_dipendente_disponibile(DATE, DATE, DECIMAL, VARCHAR) TO authenticated;

SELECT '✅ Priorità aggiornate: 🥇 Dipendente, 🥉 Titolare, 🥈 Tecnico, 🏅 Segreteria' as status;

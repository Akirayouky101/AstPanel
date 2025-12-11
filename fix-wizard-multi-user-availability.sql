-- ================================================
-- FIX: trova_n_dipendenti_disponibili Bug
-- Data: Dicembre 2024
-- Descrizione: Corregge calcolo ore includendo task_assignments e rimuove filtro date
-- ================================================

DROP FUNCTION IF EXISTS trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER);

CREATE FUNCTION trova_n_dipendenti_disponibili(
    p_data_inizio DATE,
    p_data_fine DATE,
    p_ore_necessarie DECIMAL DEFAULT 8,
    p_numero_dipendenti INTEGER DEFAULT 3
) RETURNS TABLE(
    user_id UUID,
    nome_completo TEXT,
    email VARCHAR,
    ruolo VARCHAR,
    costo_orario DECIMAL,
    task_attivi INTEGER,
    ore_impegnate DECIMAL,
    ore_disponibili DECIMAL,
    percentuale_disponibilita INTEGER,
    score INTEGER,
    posizione INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH 
    -- Ore da task diretti
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
    -- Ore da task multi-user
    ore_multiuser AS (
        SELECT 
            u.id as user_id,
            COUNT(ta.task_id) as task_count_multi,
            COALESCE(SUM(ta.ore_assegnate), 0) as ore_totali_multi
        FROM users u
        LEFT JOIN task_assignments ta ON ta.user_id = u.id
        LEFT JOIN tasks t ON ta.task_id = t.id 
            AND t.stato NOT IN ('completata', 'annullata')
        WHERE u.ruolo IN ('Dipendente', 'Titolare', 'Tecnico', 'Segreteria')
        GROUP BY u.id
    ),
    carico_utenti AS (
        SELECT 
            u.id,
            (u.nome || ' ' || u.cognome) as nome_completo,
            u.email,
            u.ruolo,
            COALESCE(u.costo_orario, 0) as costo_ora,
            (COALESCE(od.task_count, 0) + COALESCE(om.task_count_multi, 0)) as task_count,
            (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali_multi, 0)) as ore_task,
            (40 - (COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali_multi, 0))) as ore_libere,
            (100 - LEAST(100, ((COALESCE(od.ore_totali, 0) + COALESCE(om.ore_totali_multi, 0)) / 40 * 100))) as disponibilita,
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
        WHERE u.ruolo IN ('Dipendente', 'Tecnico', 'Titolare', 'Segreteria')
    ),
    availability_check AS (
        SELECT 
            cu.*,
            CASE 
                WHEN cu.ore_libere >= p_ore_necessarie THEN 100
                WHEN cu.ore_libere > 0 THEN (cu.ore_libere / p_ore_necessarie * 100)
                ELSE 0
            END as score_disponibilita,
            -- ORDINA: Prima per ruolo, poi per score, poi per task count
            ROW_NUMBER() OVER (ORDER BY 
                cu.prio_ruolo DESC,
                CASE 
                    WHEN cu.ore_libere >= p_ore_necessarie THEN 100
                    WHEN cu.ore_libere > 0 THEN (cu.ore_libere / p_ore_necessarie * 100)
                    ELSE 0
                END DESC, 
                cu.task_count ASC
            ) as pos
        FROM carico_utenti cu
    )
    SELECT 
        ac.id,
        ac.nome_completo::TEXT,
        ac.email,
        ac.ruolo,
        ac.costo_ora::DECIMAL,
        ac.task_count::INTEGER,
        ac.ore_task::DECIMAL,
        ac.ore_libere::DECIMAL,
        ac.disponibilita::INTEGER,
        ac.score_disponibilita::INTEGER,
        ac.pos::INTEGER
    FROM availability_check ac
    WHERE ac.ore_libere > 0
    ORDER BY ac.pos ASC
    LIMIT p_numero_dipendenti;
END;
$$ LANGUAGE plpgsql;

-- Permissions
ALTER FUNCTION trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER) TO authenticated;

SELECT '✅ trova_n_dipendenti_disponibili aggiornata - ora calcola ore corrette!' as status;

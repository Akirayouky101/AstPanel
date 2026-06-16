-- =====================================================
-- FIX: Disponibilità non conta task multi-utente
-- Problema: get_dashboard_disponibilita() e check_urgenza_veloce()
-- guardavano solo tasks.assigned_user_id, ignorando task_assignments
-- =====================================================

DROP FUNCTION IF EXISTS get_dashboard_disponibilita() CASCADE;
DROP FUNCTION IF EXISTS check_urgenza_veloce() CASCADE;

-- 1. get_dashboard_disponibilita() — include task_assignments
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
    priorita INTEGER,
    priorita_ruolo INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH
    -- Task assegnati direttamente (singolo utente)
    task_diretti AS (
        SELECT
            u.id as user_id,
            COUNT(t.id) as task_count,
            COALESCE(SUM(t.ore_stimate), 0) as ore_totali
        FROM users u
        LEFT JOIN tasks t ON t.assigned_user_id = u.id
            AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato')
        GROUP BY u.id
    ),
    -- Task assegnati via task_assignments (multi-utente)
    task_multi AS (
        SELECT
            u.id as user_id,
            COUNT(DISTINCT ta.task_id) as task_count,
            COALESCE(SUM(COALESCE(ta.ore_assegnate, t.ore_stimate, 0)), 0) as ore_totali
        FROM users u
        LEFT JOIN task_assignments ta ON ta.user_id = u.id
        LEFT JOIN tasks t ON ta.task_id = t.id
            AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato')
        GROUP BY u.id
    ),
    carico_corrente AS (
        SELECT
            u.id,
            (u.nome || ' ' || u.cognome) as nome_completo,
            u.email,
            u.ruolo,
            (COALESCE(td.task_count, 0) + COALESCE(tm.task_count, 0)) as task_attivi,
            (COALESCE(td.ore_totali, 0) + COALESCE(tm.ore_totali, 0)) as ore_impegnate,
            GREATEST(0, 40 - (COALESCE(td.ore_totali, 0) + COALESCE(tm.ore_totali, 0))) as ore_disponibili,
            CASE
                WHEN (COALESCE(td.ore_totali, 0) + COALESCE(tm.ore_totali, 0)) >= 40 THEN 'occupato'
                WHEN (COALESCE(td.ore_totali, 0) + COALESCE(tm.ore_totali, 0)) >= 30 THEN 'quasi_pieno'
                WHEN (COALESCE(td.ore_totali, 0) + COALESCE(tm.ore_totali, 0)) >= 15 THEN 'disponibile'
                ELSE 'molto_disponibile'
            END as stato_disponibilita,
            CASE LOWER(u.ruolo)
                WHEN 'dipendente' THEN 4
                WHEN 'titolare' THEN 3
                WHEN 'tecnico' THEN 2
                WHEN 'segreteria' THEN 1
                ELSE 0
            END as prio_ruolo
        FROM users u
        LEFT JOIN task_diretti td ON td.user_id = u.id
        LEFT JOIN task_multi tm ON tm.user_id = u.id
        WHERE u.stato = 'attivo'
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
    ORDER BY cc.prio_ruolo DESC, 
        CASE cc.stato_disponibilita
            WHEN 'molto_disponibile' THEN 4
            WHEN 'disponibile' THEN 3
            WHEN 'quasi_pieno' THEN 2
            WHEN 'occupato' THEN 1
        END DESC,
        cc.ore_disponibili DESC;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_dashboard_disponibilita TO authenticated;

-- 2. check_urgenza_veloce() — usa get_dashboard_disponibilita aggiornata
CREATE OR REPLACE FUNCTION check_urgenza_veloce()
RETURNS TABLE(
    consigliato_user_id UUID,
    consigliato_nome TEXT,
    motivo TEXT,
    ore_disponibili DECIMAL,
    task_attivi BIGINT,
    ruolo VARCHAR
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        dv.user_id,
        dv.nome_completo::TEXT,
        CASE
            WHEN dv.stato_disponibilita = 'molto_disponibile'
                THEN '✅ MOLTO DISPONIBILE - ' || dv.ore_disponibili || ' ore libere (' || dv.ruolo || ')'
            WHEN dv.stato_disponibilita = 'disponibile'
                THEN '⚠️ Disponibile - ' || dv.ore_disponibili || ' ore libere (' || dv.ruolo || ')'
            WHEN dv.stato_disponibilita = 'quasi_pieno'
                THEN '🔸 Quasi pieno - ' || dv.ore_disponibili || ' ore libere (' || dv.ruolo || ')'
            ELSE '🔴 Occupato - ' || dv.ore_disponibili || ' ore libere (' || dv.ruolo || ')'
        END as motivo,
        dv.ore_disponibili,
        dv.task_attivi,
        dv.ruolo
    FROM get_dashboard_disponibilita() dv
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION check_urgenza_veloce TO authenticated;

-- 3. calcola_carico_lavoro() — include task_assignments
DROP FUNCTION IF EXISTS calcola_carico_lavoro(UUID, DATE, DATE) CASCADE;

CREATE OR REPLACE FUNCTION calcola_carico_lavoro(
    p_user_id UUID,
    p_data_inizio DATE DEFAULT CURRENT_DATE,
    p_data_fine DATE DEFAULT CURRENT_DATE + INTERVAL '7 days'
)
RETURNS TABLE(
    user_id UUID,
    task_attivi BIGINT,
    ore_impegnate DECIMAL,
    percentuale_carico INTEGER
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH
    task_diretti AS (
        SELECT COUNT(t.id) as cnt, COALESCE(SUM(t.ore_stimate), 0) as ore
        FROM tasks t
        WHERE t.assigned_user_id = p_user_id
          AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato')
    ),
    task_multi AS (
        SELECT COUNT(DISTINCT ta.task_id) as cnt, COALESCE(SUM(COALESCE(ta.ore_assegnate, t.ore_stimate, 0)), 0) as ore
        FROM task_assignments ta
        JOIN tasks t ON ta.task_id = t.id
        WHERE ta.user_id = p_user_id
          AND t.stato NOT IN ('completata', 'annullata', 'completato', 'annullato')
    )
    SELECT
        p_user_id,
        (td.cnt + tm.cnt) as task_attivi,
        (td.ore + tm.ore)::DECIMAL as ore_impegnate,
        LEAST(100, ((td.ore + tm.ore) / 40.0 * 100))::INTEGER as percentuale_carico
    FROM task_diretti td, task_multi tm;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION calcola_carico_lavoro TO authenticated;

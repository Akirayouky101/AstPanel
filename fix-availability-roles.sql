-- =====================================================
-- FIX AVAILABILITY FUNCTIONS - Aggiorna ruoli lowercase
-- =====================================================
-- Le funzioni usavano ruoli maiuscoli ('Dipendente', 'Titolare')
-- ma ora nel DB sono lowercase ('dipendente', 'titolare', 'segreteria', 'tecnico')
-- =====================================================

-- 0. DROP delle vecchie funzioni con CASCADE
DROP FUNCTION IF EXISTS get_dashboard_disponibilita() CASCADE;
DROP FUNCTION IF EXISTS check_urgenza_veloce() CASCADE;
DROP FUNCTION IF EXISTS trova_dipendente_disponibile(DATE, DATE, DECIMAL, VARCHAR) CASCADE;

-- 1. Aggiorna get_dashboard_disponibilita() con ruoli lowercase
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
            -- Priorità per RUOLO (lowercase): dipendente > titolare > tecnico > segreteria
            CASE LOWER(u.ruolo)
                WHEN 'dipendente' THEN 4
                WHEN 'titolare' THEN 3
                WHEN 'tecnico' THEN 2
                WHEN 'segreteria' THEN 1
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
    -- ORDINA: Prima per ruolo, poi per disponibilità, poi per ore libere
    ORDER BY cc.prio_ruolo DESC, priorita DESC, cc.ore_disponibili DESC;
END;
$$ LANGUAGE plpgsql;

-- 2. Ricrea check_urgenza_veloce() (dipende da get_dashboard_disponibilita)
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
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    
    IF user_count = 0 THEN
        RETURN;
    END IF;

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
    -- Già ordinato per priorita_ruolo DESC dalla funzione
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_urgenza_veloce IS 'Check veloce per urgenze: restituisce il dipendente più disponibile ADESSO';
GRANT EXECUTE ON FUNCTION check_urgenza_veloce TO authenticated;
ALTER FUNCTION check_urgenza_veloce() OWNER TO postgres;

-- 3. Ricrea trova_n_dipendenti_disponibili() per wizard lavorazioni
DROP FUNCTION IF EXISTS trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER) CASCADE;

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
        WHERE LOWER(u.ruolo) IN ('dipendente', 'titolare', 'tecnico', 'segreteria')
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
        WHERE LOWER(u.ruolo) IN ('dipendente', 'titolare', 'tecnico', 'segreteria')
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
            -- Priorità ruolo (lowercase): dipendente > titolare > tecnico > segreteria
            CASE LOWER(u.ruolo)
                WHEN 'dipendente' THEN 4
                WHEN 'titolare' THEN 3
                WHEN 'tecnico' THEN 2
                WHEN 'segreteria' THEN 1
                ELSE 0
            END as prio_ruolo
        FROM users u
        LEFT JOIN ore_dirette od ON od.user_id = u.id
        LEFT JOIN ore_multiuser om ON om.user_id = u.id
        WHERE LOWER(u.ruolo) IN ('dipendente', 'tecnico', 'titolare', 'segreteria')
    ),
    availability_check AS (
        SELECT 
            cu.*,
            CASE 
                WHEN cu.ore_libere >= p_ore_necessarie THEN 100
                WHEN cu.ore_libere > 0 THEN (cu.ore_libere / p_ore_necessarie * 100)
                ELSE 0
            END as score_disponibilita,
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
    WHERE ac.pos <= p_numero_dipendenti
    ORDER BY ac.pos;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER) TO authenticated;
ALTER FUNCTION trova_n_dipendenti_disponibili(DATE, DATE, DECIMAL, INTEGER) OWNER TO postgres;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ AVAILABILITY FUNCTIONS AGGIORNATE!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Funzioni aggiornate:';
    RAISE NOTICE '  1. get_dashboard_disponibilita()';
    RAISE NOTICE '  2. check_urgenza_veloce()';
    RAISE NOTICE '  3. trova_n_dipendenti_disponibili()';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Priorità ruoli (dal più prioritario):';
    RAISE NOTICE '  1️⃣ dipendente   (priorità 4)';
    RAISE NOTICE '  2️⃣ titolare     (priorità 3)';
    RAISE NOTICE '  3️⃣ tecnico      (priorità 2)';
    RAISE NOTICE '  4️⃣ segreteria   (priorità 1)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Usa LOWER(u.ruolo) per case-insensitive matching';
    RAISE NOTICE '';
END $$;

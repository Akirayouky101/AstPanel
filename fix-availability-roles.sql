-- =====================================================
-- FIX AVAILABILITY FUNCTIONS - Aggiorna ruoli lowercase
-- =====================================================
-- Le funzioni usavano ruoli maiuscoli ('Dipendente', 'Titolare')
-- ma ora nel DB sono lowercase ('dipendente', 'titolare', 'segreteria', 'tecnico')
-- =====================================================

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

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ AVAILABILITY FUNCTIONS AGGIORNATE!';
    RAISE NOTICE '✅ ========================================';
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

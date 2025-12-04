-- ================================================
-- MIGRATION: Availability & Smart Assignment System
-- Data: 4 dicembre 2025
-- Descrizione: Sistema intelligente assegnazione lavorazioni
-- ================================================

-- 1. Tabella disponibilità dipendenti
CREATE TABLE IF NOT EXISTS user_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    ora_inizio TIME NOT NULL,
    ora_fine TIME NOT NULL,
    tipo VARCHAR(50) DEFAULT 'disponibile' CHECK (tipo IN ('disponibile', 'occupato', 'ferie', 'malattia', 'permesso')),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, data, ora_inizio, ora_fine)
);

-- 2. Indici per performance
CREATE INDEX IF NOT EXISTS idx_user_availability_user ON user_availability(user_id);
CREATE INDEX IF NOT EXISTS idx_user_availability_data ON user_availability(data);
CREATE INDEX IF NOT EXISTS idx_user_availability_tipo ON user_availability(tipo);

-- 3. Funzione per calcolare carico lavoro dipendente
CREATE OR REPLACE FUNCTION calcola_carico_lavoro(
    p_user_id UUID,
    p_data_inizio DATE,
    p_data_fine DATE
) RETURNS TABLE(
    user_id UUID,
    task_attivi INTEGER,
    ore_impegnate DECIMAL,
    percentuale_carico INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p_user_id,
        COUNT(t.id)::INTEGER as task_attivi,
        COALESCE(SUM(t.ore_stimate), 0)::DECIMAL as ore_impegnate,
        LEAST(100, (COALESCE(SUM(t.ore_stimate), 0) / 40 * 100))::INTEGER as percentuale_carico
    FROM tasks t
    WHERE t.assigned_user_id = p_user_id
    AND t.stato NOT IN ('completata', 'annullata')
    AND (
        (t.scadenza >= p_data_inizio AND t.scadenza <= p_data_fine)
        OR (t.data_inizio >= p_data_inizio AND t.data_inizio <= p_data_fine)
    );
END;
$$ LANGUAGE plpgsql;

-- 4. Funzione per trovare dipendente più disponibile
CREATE OR REPLACE FUNCTION trova_dipendente_disponibile(
    p_data_inizio DATE,
    p_data_fine DATE,
    p_ore_necessarie DECIMAL DEFAULT 8,
    p_ruolo VARCHAR DEFAULT NULL
) RETURNS TABLE(
    user_id UUID,
    nome_completo VARCHAR,
    email VARCHAR,
    ruolo VARCHAR,
    task_attivi INTEGER,
    ore_impegnate DECIMAL,
    ore_disponibili DECIMAL,
    percentuale_disponibilita INTEGER,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH carico_utenti AS (
        SELECT 
            u.id,
            u.nome_completo,
            u.email,
            u.ruolo,
            COUNT(t.id) as task_count,
            COALESCE(SUM(t.ore_stimate), 0) as ore_task,
            (40 - COALESCE(SUM(t.ore_stimate), 0)) as ore_libere,
            (100 - LEAST(100, (COALESCE(SUM(t.ore_stimate), 0) / 40 * 100))) as disponibilita
        FROM users u
        LEFT JOIN tasks t ON t.assigned_user_id = u.id 
            AND t.stato NOT IN ('completata', 'annullata')
            AND (
                (t.scadenza >= p_data_inizio AND t.scadenza <= p_data_fine)
                OR (t.data_inizio >= p_data_inizio AND t.data_inizio <= p_data_fine)
            )
        WHERE u.ruolo IN ('dipendente', 'admin')
        AND (p_ruolo IS NULL OR u.ruolo = p_ruolo)
        GROUP BY u.id, u.nome_completo, u.email, u.ruolo
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
        ac.nome_completo,
        ac.email,
        ac.ruolo,
        ac.task_count::INTEGER,
        ac.ore_task::DECIMAL,
        ac.ore_libere::DECIMAL,
        ac.disponibilita::INTEGER,
        ac.score_disponibilita::INTEGER
    FROM availability_check ac
    WHERE ac.ore_libere > 0
    ORDER BY ac.score_disponibilita DESC, ac.task_count ASC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- 5. View per dashboard disponibilità rapida
CREATE OR REPLACE VIEW dashboard_disponibilita AS
WITH next_week AS (
    SELECT 
        CURRENT_DATE as data_inizio,
        CURRENT_DATE + INTERVAL '7 days' as data_fine
),
carico_corrente AS (
    SELECT 
        u.id,
        u.nome_completo,
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
        END as stato_disponibilita
    FROM users u
    CROSS JOIN next_week nw
    LEFT JOIN tasks t ON t.assigned_user_id = u.id 
        AND t.stato NOT IN ('completata', 'annullata')
        AND (
            (t.scadenza >= nw.data_inizio AND t.scadenza <= nw.data_fine)
            OR (t.data_inizio >= nw.data_inizio AND t.data_inizio <= nw.data_fine)
        )
    WHERE u.ruolo IN ('dipendente', 'admin')
    GROUP BY u.id, u.nome_completo, u.email, u.ruolo
)
SELECT 
    id as user_id,
    nome_completo,
    email,
    ruolo,
    task_attivi,
    ore_impegnate,
    ore_disponibili,
    stato_disponibilita,
    CASE stato_disponibilita
        WHEN 'molto_disponibile' THEN 4
        WHEN 'disponibile' THEN 3
        WHEN 'quasi_pieno' THEN 2
        WHEN 'occupato' THEN 1
    END as priorita
FROM carico_corrente
ORDER BY priorita DESC, ore_disponibili DESC;

-- 6. Funzione per check veloce urgenze
CREATE OR REPLACE FUNCTION check_urgenza_veloce()
RETURNS TABLE(
    consigliato_user_id UUID,
    consigliato_nome VARCHAR,
    motivo TEXT,
    ore_disponibili DECIMAL,
    task_attivi INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dv.user_id,
        dv.nome_completo,
        CASE 
            WHEN dv.stato_disponibilita = 'molto_disponibile' 
                THEN '✅ MOLTO DISPONIBILE - ' || dv.ore_disponibili || ' ore libere'
            WHEN dv.stato_disponibilita = 'disponibile' 
                THEN '⚠️ Disponibile - ' || dv.ore_disponibili || ' ore libere'
            WHEN dv.stato_disponibilita = 'quasi_pieno' 
                THEN '🔸 Quasi pieno - ' || dv.ore_disponibili || ' ore libere'
            ELSE '🔴 Occupato - ' || dv.ore_disponibili || ' ore libere'
        END as motivo,
        dv.ore_disponibili,
        dv.task_attivi
    FROM dashboard_disponibilita dv
    WHERE dv.ore_disponibili > 0
    ORDER BY dv.priorita DESC, dv.ore_disponibili DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger per aggiornare timestamp
CREATE OR REPLACE FUNCTION update_availability_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_availability_timestamp
    BEFORE UPDATE ON user_availability
    FOR EACH ROW
    EXECUTE FUNCTION update_availability_timestamp();

-- 8. Commenti
COMMENT ON TABLE user_availability IS 'Gestione disponibilità e indisponibilità dipendenti';
COMMENT ON FUNCTION calcola_carico_lavoro IS 'Calcola il carico di lavoro attuale di un dipendente';
COMMENT ON FUNCTION trova_dipendente_disponibile IS 'Trova i dipendenti più disponibili per un periodo con score intelligente';
COMMENT ON VIEW dashboard_disponibilita IS 'Dashboard rapida disponibilità dipendenti prossima settimana';
COMMENT ON FUNCTION check_urgenza_veloce IS 'Check veloce per urgenze: restituisce il dipendente più disponibile ADESSO';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT * FROM dashboard_disponibilita;
-- SELECT * FROM check_urgenza_veloce();
-- SELECT * FROM trova_dipendente_disponibile(CURRENT_DATE, CURRENT_DATE + 7, 8);

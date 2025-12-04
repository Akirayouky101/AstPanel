-- ================================================
-- MIGRATION: Multi-User Assignment System
-- Data: 4 dicembre 2025
-- Descrizione: Permette assegnazione multipla utenti senza squadra
-- ================================================

-- Tabella per assegnazioni multiple
CREATE TABLE IF NOT EXISTS task_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    ruolo_assegnazione VARCHAR(50) DEFAULT 'membro' CHECK (ruolo_assegnazione IN ('responsabile', 'membro', 'supporto')),
    ore_assegnate DECIMAL(5,2) DEFAULT 0,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(task_id, user_id)
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_task_assignments_task ON task_assignments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_assignments_user ON task_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_task_assignments_ruolo ON task_assignments(ruolo_assegnazione);

-- Trigger per timestamp
CREATE OR REPLACE FUNCTION update_task_assignments_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_task_assignments_timestamp
    BEFORE UPDATE ON task_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_task_assignments_timestamp();

-- View per vedere tutte le assegnazioni con dettagli
CREATE OR REPLACE VIEW task_assignments_detail AS
SELECT 
    ta.id,
    ta.task_id,
    t.titolo as task_titolo,
    ta.user_id,
    (u.nome || ' ' || u.cognome) as user_nome,
    u.email as user_email,
    u.ruolo as user_ruolo,
    ta.ruolo_assegnazione,
    ta.ore_assegnate,
    ta.note,
    ta.created_at
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
JOIN users u ON ta.user_id = u.id;

-- Funzione per trovare N dipendenti più disponibili
CREATE OR REPLACE FUNCTION trova_n_dipendenti_disponibili(
    p_data_inizio DATE,
    p_data_fine DATE,
    p_ore_necessarie DECIMAL DEFAULT 8,
    p_numero_dipendenti INTEGER DEFAULT 3
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
    posizione INTEGER
) AS $$
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
            (100 - LEAST(100, (COALESCE(SUM(t.ore_stimate), 0) / 40 * 100))) as disponibilita
        FROM users u
        LEFT JOIN tasks t ON t.assigned_user_id = u.id 
            AND t.stato NOT IN ('completata', 'annullata')
            AND (
                (t.scadenza >= p_data_inizio AND t.scadenza <= p_data_fine)
                OR (t.data_inizio >= p_data_inizio AND t.data_inizio <= p_data_fine)
            )
        WHERE u.ruolo IN ('Dipendente', 'Tecnico', 'Titolare', 'dipendente', 'admin', 'tecnico')
        GROUP BY u.id, u.nome, u.cognome, u.email, u.ruolo
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
                CASE 
                    WHEN cu.ore_libere >= p_ore_necessarie THEN 100
                    WHEN cu.ore_libere > 0 THEN (cu.ore_libere / p_ore_necessarie * 100)
                    ELSE 0
                END DESC, cu.task_count ASC
            ) as pos
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
        ac.pos::INTEGER
    FROM availability_check ac
    WHERE ac.ore_libere > 0
    ORDER BY ac.pos ASC
    LIMIT p_numero_dipendenti;
END;
$$ LANGUAGE plpgsql;

-- Funzione per contare membri assegnati a task
CREATE OR REPLACE FUNCTION conta_membri_task(p_task_id UUID)
RETURNS INTEGER AS $$
DECLARE
    count_membri INTEGER;
BEGIN
    SELECT COUNT(*) INTO count_membri
    FROM task_assignments
    WHERE task_id = p_task_id;
    
    RETURN count_membri;
END;
$$ LANGUAGE plpgsql;

-- Commenti
COMMENT ON TABLE task_assignments IS 'Assegnazioni multiple utenti per task senza necessità di creare squadra';
COMMENT ON COLUMN task_assignments.ruolo_assegnazione IS 'Ruolo specifico per questa assegnazione: responsabile (lead), membro (worker), supporto (helper)';
COMMENT ON FUNCTION trova_n_dipendenti_disponibili IS 'Trova i N dipendenti più disponibili ordinati per score';
COMMENT ON FUNCTION conta_membri_task IS 'Conta quanti membri sono assegnati a un task';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT * FROM trova_n_dipendenti_disponibili(CURRENT_DATE, CURRENT_DATE + 7, 8, 5);
-- SELECT * FROM task_assignments_detail;

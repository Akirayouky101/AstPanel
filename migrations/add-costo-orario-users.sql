-- ================================================
-- MIGRATION: Add Hourly Rate to Users
-- Data: 4 dicembre 2025
-- Descrizione: Aggiunge costo orario ai dipendenti
-- ================================================

-- Aggiungi campo costo_orario
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS costo_orario DECIMAL(10,2) DEFAULT 0;

-- Indice per query veloci
CREATE INDEX IF NOT EXISTS idx_users_costo_orario ON users(costo_orario);

-- Commento
COMMENT ON COLUMN users.costo_orario IS 'Costo orario del dipendente in euro (es: 25.00 = 25€/ora)';

-- Aggiorna dipendenti esistenti con costo base (opzionale)
-- UPDATE users SET costo_orario = 20.00 WHERE ruolo IN ('Dipendente', 'Tecnico') AND costo_orario = 0;
-- UPDATE users SET costo_orario = 35.00 WHERE ruolo = 'Titolare' AND costo_orario = 0;

-- Funzione per calcolare costo totale lavorazione con più utenti
CREATE OR REPLACE FUNCTION calcola_costo_totale_task(p_task_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    costo_totale DECIMAL DEFAULT 0;
BEGIN
    -- Somma costo per ogni dipendente assegnato
    SELECT COALESCE(SUM(u.costo_orario * ta.ore_assegnate), 0)
    INTO costo_totale
    FROM task_assignments ta
    JOIN users u ON ta.user_id = u.id
    WHERE ta.task_id = p_task_id;
    
    RETURN costo_totale;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calcola_costo_totale_task IS 'Calcola costo totale lavorazione basato su ore assegnate e costo orario dipendenti';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT id, nome, cognome, ruolo, costo_orario FROM users;
-- SELECT calcola_costo_totale_task('[task-id]');

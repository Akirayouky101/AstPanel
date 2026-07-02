-- ============================================================
-- MIGRAZIONE: Aggiunge parent_task_id alle lavorazioni
-- ============================================================
-- Esegui nel Supabase SQL Editor
-- 
-- Scopo: permette di collegare più interventi alla stessa
-- lavorazione "madre". Tutti i figli puntano alla madre,
-- mai ad altri figli (struttura flat, non gerarchica).
-- ============================================================

ALTER TABLE tasks
    ADD COLUMN IF NOT EXISTS parent_task_id UUID
        REFERENCES tasks(id)
        ON DELETE SET NULL;

-- Indice per query veloci (trova tutti gli interventi di un cantiere)
CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id
    ON tasks(parent_task_id)
    WHERE parent_task_id IS NOT NULL;

-- RLS: stessa politica della tabella tasks (già coperta)
-- Non servono nuove policy.

DO $$ BEGIN
    RAISE NOTICE '✅ Colonna parent_task_id aggiunta a tasks';
    RAISE NOTICE '✅ Indice idx_tasks_parent_task_id creato';
END $$;

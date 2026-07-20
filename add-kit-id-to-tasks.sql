-- Aggiunge riferimento al kit sulla tabella tasks
ALTER TABLE tasks
    ADD COLUMN IF NOT EXISTS kit_id uuid REFERENCES kits(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_kit_id ON tasks(kit_id) WHERE kit_id IS NOT NULL;

COMMENT ON COLUMN tasks.kit_id IS 'Kit collegato a questa lavorazione (opzionale)';

SELECT '✅ Colonna kit_id aggiunta a tasks' AS status;

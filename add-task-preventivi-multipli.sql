-- ============================================================
-- TASK_PREVENTIVI: collegamento multi-preventivo per lavorazioni
-- Una lavorazione può essere collegata a più preventivi separati
-- (es. antintrusione + videosorveglianza nello stesso cantiere)
-- ============================================================

-- 1. Tabella junction
CREATE TABLE IF NOT EXISTS task_preventivi (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_id     UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    preventivo_id UUID NOT NULL REFERENCES preventivi(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (task_id, preventivo_id)
);

CREATE INDEX IF NOT EXISTS idx_task_preventivi_task ON task_preventivi(task_id);
CREATE INDEX IF NOT EXISTS idx_task_preventivi_preventivo ON task_preventivi(preventivo_id);

-- 2. Migra i dati esistenti: se tasks.preventivo_id è valorizzato, crea il record in task_preventivi
INSERT INTO task_preventivi (task_id, preventivo_id)
SELECT id, preventivo_id
FROM tasks
WHERE preventivo_id IS NOT NULL
ON CONFLICT (task_id, preventivo_id) DO NOTHING;

-- 3. RLS
ALTER TABLE task_preventivi ENABLE ROW LEVEL SECURITY;

CREATE POLICY "task_preventivi_select" ON task_preventivi FOR SELECT USING (true);
CREATE POLICY "task_preventivi_insert" ON task_preventivi FOR INSERT WITH CHECK (true);
CREATE POLICY "task_preventivi_delete" ON task_preventivi FOR DELETE USING (true);

RAISE NOTICE '✅ Tabella task_preventivi creata e dati migrati';

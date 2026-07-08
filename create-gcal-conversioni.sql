-- =====================================================
-- Traccia quali eventi Google Calendar sono già stati
-- convertiti in lavorazioni nel sistema AST Panel
-- =====================================================

CREATE TABLE IF NOT EXISTS gcal_conversioni (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id    TEXT NOT NULL UNIQUE,   -- ID univoco evento Google Calendar
    task_id     UUID REFERENCES tasks(id) ON DELETE SET NULL,
    titolo      TEXT,
    data_evento DATE,
    convertito_da UUID,
    convertito_il TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gcal_event_id ON gcal_conversioni(event_id);

ALTER TABLE gcal_conversioni ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gcal_all" ON gcal_conversioni;
CREATE POLICY "gcal_all" ON gcal_conversioni FOR ALL USING (true) WITH CHECK (true);

SELECT 'Tabella gcal_conversioni creata' AS status;

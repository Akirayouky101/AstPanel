-- =====================================================
-- PUSH SUBSCRIPTIONS TABLE
-- Esegui nel Supabase SQL Editor
-- =====================================================

CREATE TABLE IF NOT EXISTS push_subscriptions (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    dipendente_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    endpoint       TEXT        NOT NULL,
    key_p256dh     TEXT        NOT NULL,
    key_auth       TEXT        NOT NULL,
    user_agent     TEXT,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (dipendente_id)   -- un dispositivo per dipendente (ultimo login)
);

-- RLS
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- Il dipendente può gestire solo la propria subscription
CREATE POLICY "Dipendente gestisce la propria subscription"
    ON push_subscriptions FOR ALL
    USING  (dipendente_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (dipendente_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Il service role (Edge Function) può leggere tutte
CREATE POLICY "Service role accesso completo"
    ON push_subscriptions FOR ALL
    TO service_role USING (true) WITH CHECK (true);

-- Aggiorna automaticamente updated_at
CREATE OR REPLACE FUNCTION update_push_sub_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_push_sub_updated_at
    BEFORE UPDATE ON push_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_push_sub_timestamp();

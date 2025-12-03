-- ================================================
-- MIGRATION: Push Notifications
-- Data: 3 dicembre 2025
-- Descrizione: Tabella per salvare push subscription tokens
-- ================================================

-- 1. Creare tabella push_subscriptions
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  UNIQUE(user_id, endpoint)
);

-- 2. Creare indici per performance
CREATE INDEX IF NOT EXISTS idx_push_subs_user_id ON push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_subs_created ON push_subscriptions(created_at DESC);

-- 3. Enable RLS (opzionale - commentato perché app usa auth custom)
-- ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies (opzionale - commentato)
-- Decommentare se si usa Supabase Auth con JWT
/*
CREATE POLICY "Users can view own subscriptions"
  ON push_subscriptions FOR SELECT
  USING (user_id::text = (auth.jwt() ->> 'sub'));

CREATE POLICY "Users can insert own subscriptions"
  ON push_subscriptions FOR INSERT
  WITH CHECK (user_id::text = (auth.jwt() ->> 'sub'));

CREATE POLICY "Users can update own subscriptions"
  ON push_subscriptions FOR UPDATE
  USING (user_id::text = (auth.jwt() ->> 'sub'));

CREATE POLICY "Users can delete own subscriptions"
  ON push_subscriptions FOR DELETE
  USING (user_id::text = (auth.jwt() ->> 'sub'));
*/

-- 5. Funzione per aggiornare timestamp
CREATE OR REPLACE FUNCTION update_push_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Trigger per auto-update timestamp
DROP TRIGGER IF EXISTS update_push_subscription_timestamp ON push_subscriptions;
CREATE TRIGGER update_push_subscription_timestamp
  BEFORE UPDATE ON push_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_push_subscription_timestamp();

-- 7. Tabella per storico notifiche inviate (opzionale)
CREATE TABLE IF NOT EXISTS notification_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT, -- 'lavorazione', 'richiesta', 'comunicazione', etc
  related_id UUID,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ
);

-- 8. Indici per notification_history
CREATE INDEX IF NOT EXISTS idx_notif_history_user ON notification_history(user_id);
CREATE INDEX IF NOT EXISTS idx_notif_history_sent ON notification_history(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_history_type ON notification_history(type);

-- 9. RLS per notification_history (opzionale - commentato)
-- ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

/*
CREATE POLICY "Users can view own notifications"
  ON notification_history FOR SELECT
  USING (user_id::text = (auth.jwt() ->> 'sub'));
*/

-- 10. Commenti per documentazione
COMMENT ON TABLE push_subscriptions IS 'Subscription tokens per push notifications Web Push API';
COMMENT ON COLUMN push_subscriptions.endpoint IS 'Endpoint URL fornito dal browser';
COMMENT ON COLUMN push_subscriptions.p256dh IS 'Chiave pubblica client per encryption';
COMMENT ON COLUMN push_subscriptions.auth IS 'Auth secret per encryption';
COMMENT ON COLUMN push_subscriptions.user_agent IS 'Browser/device info per debugging';

COMMENT ON TABLE notification_history IS 'Storico notifiche push inviate agli utenti';

-- 11. Verificare la migration
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('push_subscriptions', 'notification_history')
ORDER BY table_name, ordinal_position;

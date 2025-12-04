-- ================================================
-- MIGRATION: External Integrations Support
-- Data: 4 dicembre 2025
-- Descrizione: Campi per integrazioni esterne
-- ================================================

-- 1. Aggiungi campi integrazioni alla tabella tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS google_calendar_event_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS whatsapp_message_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS email_confirmation_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_notification_sent TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}'::jsonb;

-- 2. Aggiungi campi integrazioni alla tabella clients
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS whatsapp_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS email_notifications_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS whatsapp_notifications_enabled BOOLEAN DEFAULT FALSE;

-- 3. Crea tabella per log notifiche
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Tipo notifica
    type VARCHAR(50) NOT NULL CHECK (type IN ('email', 'whatsapp', 'sms', 'push')),
    channel VARCHAR(50) NOT NULL, -- confirmation, reminder, status_update, etc
    
    -- Destinatario
    recipient VARCHAR(255) NOT NULL,
    
    -- Contenuto
    subject VARCHAR(500),
    message TEXT NOT NULL,
    
    -- Status
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'read')),
    error_message TEXT,
    
    -- External IDs
    external_message_id VARCHAR(255),
    
    -- Metadata
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Indici per performance
CREATE INDEX IF NOT EXISTS idx_notification_logs_task ON notification_logs(task_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_client ON notification_logs(client_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_type ON notification_logs(type);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON notification_logs(status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created ON notification_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_google_calendar ON tasks(google_calendar_event_id) WHERE google_calendar_event_id IS NOT NULL;

-- 5. Crea tabella per configurazione integrazioni
CREATE TABLE IF NOT EXISTS integration_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_name VARCHAR(100) UNIQUE NOT NULL,
    is_enabled BOOLEAN DEFAULT FALSE,
    
    -- Credenziali (criptate)
    api_key TEXT,
    api_secret TEXT,
    access_token TEXT,
    refresh_token TEXT,
    
    -- Configurazione
    settings JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    last_sync TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Inserisci configurazioni default
INSERT INTO integration_settings (integration_name, settings) VALUES
    ('google_calendar', '{"client_id": "", "api_key": "", "calendar_id": "primary"}'::jsonb),
    ('whatsapp_business', '{"phone_number_id": "", "access_token": "", "verify_token": ""}'::jsonb),
    ('email_smtp', '{"host": "smtp.gmail.com", "port": 587, "secure": false, "from_email": "", "from_name": "AST Panel"}'::jsonb)
ON CONFLICT (integration_name) DO NOTHING;

-- 7. Funzione per log notifiche
CREATE OR REPLACE FUNCTION log_notification(
    p_task_id UUID,
    p_client_id UUID,
    p_type VARCHAR,
    p_channel VARCHAR,
    p_recipient VARCHAR,
    p_subject VARCHAR,
    p_message TEXT
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO notification_logs (
        task_id,
        client_id,
        type,
        channel,
        recipient,
        subject,
        message,
        status
    ) VALUES (
        p_task_id,
        p_client_id,
        p_type,
        p_channel,
        p_recipient,
        p_subject,
        p_message,
        'pending'
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Funzione per aggiornare status notifica
CREATE OR REPLACE FUNCTION update_notification_status(
    p_log_id UUID,
    p_status VARCHAR,
    p_error_message TEXT DEFAULT NULL,
    p_external_id VARCHAR DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE notification_logs
    SET 
        status = p_status,
        error_message = p_error_message,
        external_message_id = COALESCE(p_external_id, external_message_id),
        sent_at = CASE WHEN p_status = 'sent' THEN NOW() ELSE sent_at END,
        delivered_at = CASE WHEN p_status = 'delivered' THEN NOW() ELSE delivered_at END,
        read_at = CASE WHEN p_status = 'read' THEN NOW() ELSE read_at END
    WHERE id = p_log_id;
END;
$$ LANGUAGE plpgsql;

-- 9. View per statistiche notifiche
CREATE OR REPLACE VIEW notification_stats AS
SELECT 
    type,
    channel,
    status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'sent') as sent_count,
    COUNT(*) FILTER (WHERE status = 'delivered') as delivered_count,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (delivered_at - sent_at)))) as avg_delivery_time_seconds
FROM notification_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY type, channel, status;

-- 10. Commenti
COMMENT ON TABLE notification_logs IS 'Log completo di tutte le notifiche inviate (email, WhatsApp, SMS, push)';
COMMENT ON TABLE integration_settings IS 'Configurazione credenziali e settings per integrazioni esterne';
COMMENT ON FUNCTION log_notification IS 'Crea log notifica e restituisce ID per tracking';
COMMENT ON FUNCTION update_notification_status IS 'Aggiorna status notifica con timestamp automatici';

-- ================================================
-- VERIFICA
-- ================================================
-- SELECT * FROM integration_settings;
-- SELECT * FROM notification_stats;

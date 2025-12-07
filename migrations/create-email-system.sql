-- Migration: Sistema Email per Commercialista
-- Descrizione: Gestione destinatari email e log invii mensili PDF
-- Autore: AST Panel Admin System
-- Data: 2024

-- =====================================================
-- Tabella Destinatari Email (max 5)
-- =====================================================
CREATE TABLE IF NOT EXISTS email_destinatari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) DEFAULT 'commercialista', -- commercialista, consulente, altro
    attivo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Constraint: massimo 5 destinatari attivi
CREATE OR REPLACE FUNCTION check_max_destinatari()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.attivo = TRUE THEN
        IF (SELECT COUNT(*) FROM email_destinatari WHERE attivo = TRUE) >= 5 THEN
            RAISE EXCEPTION 'Massimo 5 destinatari email attivi consentiti';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_max_destinatari
    BEFORE INSERT OR UPDATE ON email_destinatari
    FOR EACH ROW
    EXECUTE FUNCTION check_max_destinatari();

-- Indici
CREATE INDEX idx_email_destinatari_attivo ON email_destinatari(attivo);

-- Commenti
COMMENT ON TABLE email_destinatari IS 'Lista destinatari email per invio PDF mensili (max 5 attivi)';
COMMENT ON COLUMN email_destinatari.tipo IS 'Tipo destinatario: commercialista, consulente, altro';
COMMENT ON COLUMN email_destinatari.attivo IS 'Se FALSE, non riceverà più email';

-- =====================================================
-- Tabella Log Invii Email
-- =====================================================
CREATE TABLE IF NOT EXISTS email_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    destinatario_id UUID REFERENCES email_destinatari(id) ON DELETE SET NULL,
    email_destinatario VARCHAR(255) NOT NULL, -- Salva email anche se destinatario eliminato
    oggetto TEXT NOT NULL,
    periodo_riferimento VARCHAR(20) NOT NULL, -- es: '2024-12' per dicembre 2024
    anno_mese DATE NOT NULL, -- Primo giorno del mese (es: 2024-12-01)
    pdf_filename VARCHAR(255), -- Nome file PDF generato
    pdf_size_kb INTEGER, -- Dimensione PDF in KB
    totale_dipendenti INTEGER, -- Numero dipendenti nel report
    totale_ore_lavorate DECIMAL(10, 2), -- Totale ore nel periodo
    totale_costo DECIMAL(10, 2), -- Costo totale calcolato
    stato VARCHAR(50) DEFAULT 'pending', -- pending, sent, failed
    errore_invio TEXT, -- Messaggio errore se failed
    inviato_da UUID REFERENCES users(id), -- Admin che ha inviato
    inviato_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indici
CREATE INDEX idx_email_log_periodo ON email_log(anno_mese DESC);
CREATE INDEX idx_email_log_stato ON email_log(stato);
CREATE INDEX idx_email_log_destinatario ON email_log(destinatario_id);

-- Commenti
COMMENT ON TABLE email_log IS 'Storico completo di tutti gli invii email con PDF allegati';
COMMENT ON COLUMN email_log.periodo_riferimento IS 'Formato YYYY-MM per identificare il mese';
COMMENT ON COLUMN email_log.stato IS 'pending: in coda, sent: inviato, failed: errore';

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================
ALTER TABLE email_destinatari ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_log ENABLE ROW LEVEL SECURITY;

-- Solo admin possono vedere destinatari
CREATE POLICY "Solo admin vedono destinatari email" 
ON email_destinatari FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Solo admin possono inserire/modificare destinatari
CREATE POLICY "Solo admin gestiscono destinatari" 
ON email_destinatari FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Solo admin possono vedere log email
CREATE POLICY "Solo admin vedono log email" 
ON email_log FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Solo admin possono inserire log email
CREATE POLICY "Solo admin inseriscono log email" 
ON email_log FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- =====================================================
-- Function Helper: Get Email Report Data
-- =====================================================
CREATE OR REPLACE FUNCTION get_email_report_data(
    p_anno INTEGER,
    p_mese INTEGER
)
RETURNS TABLE (
    dipendente_nome TEXT,
    dipendente_cognome TEXT,
    dipendente_ruolo VARCHAR,
    costo_orario DECIMAL,
    totale_ore DECIMAL,
    totale_costo DECIMAL,
    giorni_lavorati INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.nome,
        u.cognome,
        u.ruolo,
        u.costo_orario,
        COALESCE(SUM(t.ore_lavorate), 0) AS totale_ore,
        COALESCE(SUM(t.ore_lavorate * u.costo_orario), 0) AS totale_costo,
        COUNT(DISTINCT t.data)::INTEGER AS giorni_lavorati
    FROM users u
    LEFT JOIN timbrature t ON t.user_id = u.id
        AND EXTRACT(YEAR FROM t.data) = p_anno
        AND EXTRACT(MONTH FROM t.data) = p_mese
        AND t.stato = 'approved'
    WHERE u.ruolo NOT IN ('Titolare', 'Amministratore') -- Escludi admin dal report
    GROUP BY u.id, u.nome, u.cognome, u.ruolo, u.costo_orario
    HAVING COALESCE(SUM(t.ore_lavorate), 0) > 0 -- Solo dipendenti con ore lavorate
    ORDER BY u.cognome, u.nome;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Function Helper: Check Email Already Sent
-- =====================================================
CREATE OR REPLACE FUNCTION check_email_already_sent(
    p_anno INTEGER,
    p_mese INTEGER,
    p_email VARCHAR
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM email_log
        WHERE anno_mese = DATE(p_anno || '-' || LPAD(p_mese::TEXT, 2, '0') || '-01')
        AND email_destinatario = p_email
        AND stato = 'sent'
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Seed Data (esempio)
-- =====================================================
INSERT INTO email_destinatari (email, nome, tipo, attivo) VALUES
    ('commercialista@example.com', 'Studio Commercialista Rossi', 'commercialista', TRUE),
    ('consulente@example.com', 'Consulente del Lavoro', 'consulente', TRUE)
ON CONFLICT (email) DO NOTHING;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON email_destinatari TO authenticated;
GRANT SELECT, INSERT ON email_log TO authenticated;
GRANT EXECUTE ON FUNCTION get_email_report_data(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION check_email_already_sent(INTEGER, INTEGER, VARCHAR) TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Sistema Email creato con successo!';
    RAISE NOTICE '📧 Tabelle: email_destinatari (max 5), email_log';
    RAISE NOTICE '🔒 RLS policies attive per admin';
    RAISE NOTICE '⚙️ Helper functions: get_email_report_data, check_email_already_sent';
    RAISE NOTICE '🌱 Seed data: 2 destinatari esempio inseriti';
END $$;

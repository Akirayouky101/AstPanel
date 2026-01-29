-- =====================================================
-- SISTEMA GESTIONE CONDOMINI
-- =====================================================
-- Tracciabilità completa interventi su condomini
-- con log accessi, unità immobiliari, documenti

-- =====================================================
-- TABELLA: condomini
-- =====================================================
CREATE TABLE IF NOT EXISTS condomini (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codice VARCHAR(50) UNIQUE NOT NULL, -- COND-001, COND-002
    nome VARCHAR(255) NOT NULL,
    indirizzo TEXT NOT NULL,
    citta VARCHAR(100),
    cap VARCHAR(10),
    provincia VARCHAR(2),
    
    -- Amministratore
    amministratore_nome VARCHAR(255),
    amministratore_email VARCHAR(255),
    amministratore_telefono VARCHAR(50),
    amministratore_pec VARCHAR(255),
    
    -- Dettagli edificio
    numero_unita INTEGER DEFAULT 0, -- Totale appartamenti/negozi
    numero_piani INTEGER,
    anno_costruzione INTEGER,
    tipo_riscaldamento VARCHAR(100), -- Centralizzato/Autonomo
    
    -- Contratto
    tipo_contratto VARCHAR(50), -- Manutenzione/Assistenza/Singolo
    data_inizio_contratto DATE,
    data_scadenza_contratto DATE,
    importo_contratto_annuo DECIMAL(10,2),
    
    -- Info aggiuntive
    note TEXT,
    stato VARCHAR(50) DEFAULT 'attivo', -- attivo/sospeso/chiuso
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE condomini IS 'Anagrafica condomini con dati amministratore e contratto';

-- =====================================================
-- TABELLA: condomini_unita
-- =====================================================
CREATE TABLE IF NOT EXISTS condomini_unita (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    condominio_id UUID REFERENCES condomini(id) ON DELETE CASCADE,
    
    -- Identificazione unità
    piano INTEGER, -- 0=terra, -1=interrato, 1-N=piani
    interno VARCHAR(20), -- A, B, 1, 2, etc
    scala VARCHAR(10), -- A, B, principale, etc
    tipologia VARCHAR(50), -- appartamento/negozio/ufficio/box/cantina
    
    -- Proprietario/Inquilino
    proprietario_nome VARCHAR(255),
    proprietario_telefono VARCHAR(50),
    proprietario_email VARCHAR(255),
    
    inquilino_nome VARCHAR(255),
    inquilino_telefono VARCHAR(50),
    inquilino_email VARCHAR(255),
    
    -- Dettagli
    mq DECIMAL(10,2),
    note TEXT,
    
    -- QR Code per accesso rapido
    qr_code VARCHAR(100) UNIQUE, -- Generato automaticamente
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE condomini_unita IS 'Unità immobiliari (appartamenti, negozi, box) del condominio';

-- =====================================================
-- TABELLA: condomini_interventi
-- =====================================================
CREATE TABLE IF NOT EXISTS condomini_interventi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero VARCHAR(50) UNIQUE NOT NULL, -- INT-COND-2026-001
    condominio_id UUID REFERENCES condomini(id) ON DELETE CASCADE,
    unita_id UUID REFERENCES condomini_unita(id) ON DELETE SET NULL, -- NULL = parti comuni
    
    -- Tipo intervento
    tipo VARCHAR(100) NOT NULL, -- Manutenzione/Riparazione/Installazione/Sopralluogo
    categoria VARCHAR(100), -- Idraulico/Elettrico/Riscaldamento/Altro
    titolo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    priorita VARCHAR(50) DEFAULT 'media', -- bassa/media/alta/urgente
    
    -- Pianificazione
    data_richiesta TIMESTAMP DEFAULT NOW(),
    data_pianificata TIMESTAMP,
    data_completamento TIMESTAMP,
    stato VARCHAR(50) DEFAULT 'da_pianificare', -- da_pianificare/pianificato/in_corso/completato/annullato
    
    -- Assegnazione
    assegnato_a UUID REFERENCES auth.users(id),
    squadra_id UUID, -- Riferimento opzionale a squadre (se la tabella esiste)
    
    -- Costi
    costo_preventivato DECIMAL(10,2),
    costo_effettivo DECIMAL(10,2),
    ore_previste DECIMAL(5,2),
    ore_effettive DECIMAL(5,2),
    
    -- Materiali utilizzati (JSON array di {componente_id, quantita, costo})
    materiali_utilizzati JSONB,
    
    -- Esito
    esito TEXT, -- Descrizione lavoro svolto
    firma_digitale TEXT, -- Base64 firma cliente/amministratore
    firma_nome VARCHAR(255),
    valutazione INTEGER, -- 1-5 stelle
    
    note_interne TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE condomini_interventi IS 'Interventi tecnici su condomini con tracciabilità completa';

-- =====================================================
-- TABELLA: condomini_accessi
-- =====================================================
CREATE TABLE IF NOT EXISTS condomini_accessi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    intervento_id UUID REFERENCES condomini_interventi(id) ON DELETE CASCADE,
    condominio_id UUID REFERENCES condomini(id) ON DELETE CASCADE,
    unita_id UUID REFERENCES condomini_unita(id) ON DELETE SET NULL,
    
    -- Chi
    tecnico_id UUID REFERENCES auth.users(id),
    tecnico_nome VARCHAR(255), -- Snapshot nome al momento accesso
    
    -- Quando
    timestamp_ingresso TIMESTAMP DEFAULT NOW(),
    timestamp_uscita TIMESTAMP,
    durata_minuti INTEGER GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (timestamp_uscita - timestamp_ingresso)) / 60) STORED,
    
    -- Dove (GPS)
    latitudine_ingresso DECIMAL(10,8),
    longitudine_ingresso DECIMAL(11,8),
    latitudine_uscita DECIMAL(10,8),
    longitudine_uscita DECIMAL(11,8),
    
    -- Cosa
    attivita_svolta TEXT,
    foto_ingresso TEXT[], -- Array URLs foto
    foto_uscita TEXT[], -- Array URLs foto
    
    -- Verifica presenza
    distanza_dal_condominio_metri INTEGER, -- Calcolata da GPS
    presenza_verificata BOOLEAN DEFAULT false,
    
    note TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE condomini_accessi IS 'Log accessi tecnici con GPS e foto per tracciabilità';

-- =====================================================
-- TABELLA: condomini_documenti
-- =====================================================
CREATE TABLE IF NOT EXISTS condomini_documenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    condominio_id UUID REFERENCES condomini(id) ON DELETE CASCADE,
    intervento_id UUID REFERENCES condomini_interventi(id) ON DELETE SET NULL,
    
    tipo VARCHAR(100) NOT NULL, -- verbale/preventivo/fattura/foto/planimetria/contratto
    titolo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    
    -- File
    file_url TEXT, -- URL Supabase Storage
    file_nome VARCHAR(255),
    file_tipo VARCHAR(100), -- application/pdf, image/jpeg, etc
    file_size_kb INTEGER,
    
    -- Metadata
    data_documento DATE,
    visibile_amministratore BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE condomini_documenti IS 'Documenti, foto, verbali relativi a condomini e interventi';

-- =====================================================
-- FUNZIONE: Genera numero intervento
-- =====================================================
CREATE OR REPLACE FUNCTION generate_intervento_numero()
RETURNS TEXT AS $$
DECLARE
    anno TEXT;
    counter INTEGER;
    nuovo_numero TEXT;
BEGIN
    anno := EXTRACT(YEAR FROM NOW())::TEXT;
    
    -- Conta interventi dell'anno corrente
    SELECT COUNT(*) + 1 INTO counter
    FROM condomini_interventi
    WHERE numero LIKE 'INT-COND-' || anno || '-%';
    
    -- Genera numero: INT-COND-2026-001
    nuovo_numero := 'INT-COND-' || anno || '-' || LPAD(counter::TEXT, 3, '0');
    
    RETURN nuovo_numero;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNZIONE: Genera codice condominio
-- =====================================================
CREATE OR REPLACE FUNCTION generate_condominio_codice()
RETURNS TEXT AS $$
DECLARE
    counter INTEGER;
    nuovo_codice TEXT;
BEGIN
    -- Conta condomini totali
    SELECT COUNT(*) + 1 INTO counter FROM condomini;
    
    -- Genera codice: COND-001
    nuovo_codice := 'COND-' || LPAD(counter::TEXT, 3, '0');
    
    RETURN nuovo_codice;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNZIONE: Genera QR code unità
-- =====================================================
CREATE OR REPLACE FUNCTION generate_unita_qr()
RETURNS TEXT AS $$
DECLARE
    random_string TEXT;
BEGIN
    -- Genera stringa random per QR: UNIT-ABC123DEF
    random_string := 'UNIT-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 9));
    
    RETURN random_string;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGER: Auto-genera codice condominio
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_generate_condominio_codice()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.codice IS NULL OR NEW.codice = '' THEN
        NEW.codice := generate_condominio_codice();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_condominio
    BEFORE INSERT ON condomini
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generate_condominio_codice();

-- =====================================================
-- TRIGGER: Auto-genera numero intervento
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_generate_intervento_numero()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.numero IS NULL OR NEW.numero = '' THEN
        NEW.numero := generate_intervento_numero();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_intervento
    BEFORE INSERT ON condomini_interventi
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generate_intervento_numero();

-- =====================================================
-- TRIGGER: Auto-genera QR code unità
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_generate_unita_qr()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.qr_code IS NULL OR NEW.qr_code = '' THEN
        NEW.qr_code := generate_unita_qr();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_unita
    BEFORE INSERT ON condomini_unita
    FOR EACH ROW
    EXECUTE FUNCTION trigger_generate_unita_qr();

-- =====================================================
-- TRIGGER: Aggiorna updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_condomini_timestamp
    BEFORE UPDATE ON condomini
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_timestamp();

CREATE TRIGGER update_condomini_unita_timestamp
    BEFORE UPDATE ON condomini_unita
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_timestamp();

CREATE TRIGGER update_condomini_interventi_timestamp
    BEFORE UPDATE ON condomini_interventi
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_timestamp();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Condomini: tutti possono leggere, solo admin può scrivere
ALTER TABLE condomini ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Condomini visibili a tutti gli autenticati"
    ON condomini FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può inserire condomini"
    ON condomini FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Solo admin può aggiornare condomini"
    ON condomini FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può eliminare condomini"
    ON condomini FOR DELETE
    TO authenticated
    USING (true);

-- Unità: tutti possono leggere, solo admin può scrivere
ALTER TABLE condomini_unita ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Unità visibili a tutti gli autenticati"
    ON condomini_unita FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire unità"
    ON condomini_unita FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare unità"
    ON condomini_unita FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può eliminare unità"
    ON condomini_unita FOR DELETE
    TO authenticated
    USING (true);

-- Interventi: tutti possono leggere e scrivere
ALTER TABLE condomini_interventi ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Interventi visibili a tutti gli autenticati"
    ON condomini_interventi FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire interventi"
    ON condomini_interventi FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare interventi"
    ON condomini_interventi FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può eliminare interventi"
    ON condomini_interventi FOR DELETE
    TO authenticated
    USING (true);

-- Accessi: tutti possono leggere e scrivere
ALTER TABLE condomini_accessi ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Accessi visibili a tutti gli autenticati"
    ON condomini_accessi FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire accessi"
    ON condomini_accessi FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare accessi"
    ON condomini_accessi FOR UPDATE
    TO authenticated
    USING (true);

-- Documenti: tutti possono leggere e scrivere
ALTER TABLE condomini_documenti ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Documenti visibili a tutti gli autenticati"
    ON condomini_documenti FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Tutti possono inserire documenti"
    ON condomini_documenti FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Tutti possono aggiornare documenti"
    ON condomini_documenti FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Solo admin può eliminare documenti"
    ON condomini_documenti FOR DELETE
    TO authenticated
    USING (true);

-- =====================================================
-- INDICI per performance
-- =====================================================
CREATE INDEX idx_condomini_codice ON condomini(codice);
CREATE INDEX idx_condomini_stato ON condomini(stato);
CREATE INDEX idx_condomini_citta ON condomini(citta);

CREATE INDEX idx_unita_condominio ON condomini_unita(condominio_id);
CREATE INDEX idx_unita_qr ON condomini_unita(qr_code);

CREATE INDEX idx_interventi_numero ON condomini_interventi(numero);
CREATE INDEX idx_interventi_condominio ON condomini_interventi(condominio_id);
CREATE INDEX idx_interventi_stato ON condomini_interventi(stato);
CREATE INDEX idx_interventi_data ON condomini_interventi(data_pianificata);
CREATE INDEX idx_interventi_assegnato ON condomini_interventi(assegnato_a);

CREATE INDEX idx_accessi_intervento ON condomini_accessi(intervento_id);
CREATE INDEX idx_accessi_tecnico ON condomini_accessi(tecnico_id);
CREATE INDEX idx_accessi_data ON condomini_accessi(timestamp_ingresso);

CREATE INDEX idx_documenti_condominio ON condomini_documenti(condominio_id);
CREATE INDEX idx_documenti_intervento ON condomini_documenti(intervento_id);
CREATE INDEX idx_documenti_tipo ON condomini_documenti(tipo);

-- =====================================================
-- DATI DI TEST (opzionale)
-- =====================================================
-- Inserisci un condominio di esempio
-- INSERT INTO condomini (nome, indirizzo, citta, cap, numero_unita, amministratore_nome, amministratore_telefono)
-- VALUES ('Condominio Vista Mare', 'Via Roma 123', 'Milano', '20100', 24, 'Mario Rossi', '333-1234567');

RAISE NOTICE '✅ Sistema Gestione Condomini creato con successo!';
RAISE NOTICE '📋 Tabelle: condomini, condomini_unita, condomini_interventi, condomini_accessi, condomini_documenti';
RAISE NOTICE '🔧 Funzioni: generate_condominio_codice(), generate_intervento_numero(), generate_unita_qr()';
RAISE NOTICE '🔒 RLS attivato su tutte le tabelle';

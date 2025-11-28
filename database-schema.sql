-- =====================================================
-- AST PANEL - Database Schema for Supabase
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS TABLE (Dipendenti e Admin)
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cognome VARCHAR(100) NOT NULL,
    ruolo VARCHAR(50) NOT NULL CHECK (ruolo IN ('admin', 'dipendente', 'tecnico')),
    telefono VARCHAR(50),
    avatar TEXT,
    reparto VARCHAR(100),
    data_assunzione DATE,
    stato VARCHAR(20) DEFAULT 'attivo' CHECK (stato IN ('attivo', 'inattivo', 'sospeso')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- CLIENTS TABLE (Clienti)
-- =====================================================
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ragione_sociale VARCHAR(255) NOT NULL,
    nome VARCHAR(100),
    cognome VARCHAR(100),
    tipo_cliente VARCHAR(50) CHECK (tipo_cliente IN ('azienda', 'privato')),
    indirizzo TEXT,
    citta VARCHAR(100),
    provincia VARCHAR(10),
    cap VARCHAR(10),
    latitudine DECIMAL(10, 8),
    longitudine DECIMAL(11, 8),
    telefono VARCHAR(50),
    email VARCHAR(255),
    pec VARCHAR(255),
    partita_iva VARCHAR(50),
    codice_fiscale VARCHAR(50),
    settore VARCHAR(100),
    note TEXT,
    data_inizio_rapporto DATE,
    stato VARCHAR(20) DEFAULT 'attivo' CHECK (stato IN ('attivo', 'inattivo', 'potenziale')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TEAMS TABLE (Squadre)
-- =====================================================
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    descrizione TEXT,
    colore VARCHAR(7) DEFAULT '#3b82f6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TEAM_MEMBERS TABLE (Relazione membri squadra)
-- =====================================================
CREATE TABLE team_members (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    ruolo_squadra VARCHAR(50) DEFAULT 'membro',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

-- =====================================================
-- COMPONENTS TABLE (Inventario componenti)
-- =====================================================
CREATE TABLE components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(255) NOT NULL,
    codice VARCHAR(100) UNIQUE,
    categoria VARCHAR(100) NOT NULL,
    descrizione TEXT,
    quantita_disponibile INTEGER DEFAULT 0,
    unita_misura VARCHAR(50) DEFAULT 'pz',
    prezzo_unitario DECIMAL(10, 2),
    fornitore VARCHAR(255),
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TASKS TABLE (Lavorazioni)
-- =====================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titolo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    stato VARCHAR(50) DEFAULT 'da_fare' CHECK (stato IN ('da_fare', 'in_corso', 'revisione', 'completato', 'annullato')),
    priorita VARCHAR(20) DEFAULT 'media' CHECK (priorita IN ('bassa', 'media', 'alta')),
    scadenza DATE,
    data_inizio DATE,
    data_completamento DATE,
    progresso INTEGER DEFAULT 0 CHECK (progresso >= 0 AND progresso <= 100),
    note_progresso TEXT,
    
    -- Assegnazione singola o squadra
    assigned_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    assigned_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    
    -- Metadata
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: deve essere assegnato o a un utente o a un team, non entrambi
    CONSTRAINT check_assignment CHECK (
        (assigned_user_id IS NOT NULL AND assigned_team_id IS NULL) OR
        (assigned_user_id IS NULL AND assigned_team_id IS NOT NULL)
    )
);

-- =====================================================
-- TASK_COMPONENTS TABLE (Componenti assegnati ai task)
-- =====================================================
CREATE TABLE task_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    component_id UUID REFERENCES components(id) ON DELETE CASCADE,
    quantita INTEGER NOT NULL DEFAULT 1,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- REQUESTS TABLE (Richieste dipendenti)
-- =====================================================
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL,
    titolo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    stato VARCHAR(50) DEFAULT 'pendente' CHECK (stato IN ('pendente', 'approvata', 'rifiutata', 'in_lavorazione')),
    priorita VARCHAR(20) DEFAULT 'normale' CHECK (priorita IN ('bassa', 'normale', 'alta', 'urgente')),
    risposta TEXT,
    risposto_da UUID REFERENCES users(id) ON DELETE SET NULL,
    risposto_il TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- COMMUNICATIONS TABLE (Comunicazioni)
-- =====================================================
CREATE TABLE communications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titolo VARCHAR(255) NOT NULL,
    messaggio TEXT NOT NULL,
    tipo VARCHAR(50) DEFAULT 'generale' CHECK (tipo IN ('generale', 'urgente', 'informativa', 'manutenzione')),
    destinatari VARCHAR(50) DEFAULT 'tutti' CHECK (destinatari IN ('tutti', 'admin', 'dipendenti', 'specifici')),
    pubblicato_da UUID REFERENCES users(id) ON DELETE SET NULL,
    allegati JSONB,
    letta_da UUID[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES per performance
-- =====================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_ruolo ON users(ruolo);
CREATE INDEX idx_users_stato ON users(stato);

-- Clients indexes
CREATE INDEX idx_clients_ragione_sociale ON clients(ragione_sociale);
CREATE INDEX idx_clients_stato ON clients(stato);
CREATE INDEX idx_clients_tipo ON clients(tipo_cliente);

-- Tasks indexes
CREATE INDEX idx_tasks_stato ON tasks(stato);
CREATE INDEX idx_tasks_priorita ON tasks(priorita);
CREATE INDEX idx_tasks_scadenza ON tasks(scadenza);
CREATE INDEX idx_tasks_client_id ON tasks(client_id);
CREATE INDEX idx_tasks_assigned_user ON tasks(assigned_user_id);
CREATE INDEX idx_tasks_assigned_team ON tasks(assigned_team_id);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);

-- Components indexes
CREATE INDEX idx_components_categoria ON components(categoria);
CREATE INDEX idx_components_codice ON components(codice);

-- Requests indexes
CREATE INDEX idx_requests_user_id ON requests(user_id);
CREATE INDEX idx_requests_stato ON requests(stato);
CREATE INDEX idx_requests_tipo ON requests(tipo);

-- Communications indexes
CREATE INDEX idx_communications_tipo ON communications(tipo);
CREATE INDEX idx_communications_destinatari ON communications(destinatari);

-- =====================================================
-- TRIGGERS per updated_at automatico
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_components_updated_at BEFORE UPDATE ON components
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requests_updated_at BEFORE UPDATE ON requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_communications_updated_at BEFORE UPDATE ON communications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS (Row Level Security) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE components ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE communications ENABLE ROW LEVEL SECURITY;

-- Policy per admin: accesso completo
CREATE POLICY admin_all ON users FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON clients FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON teams FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON team_members FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON components FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON tasks FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON task_components FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON requests FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
CREATE POLICY admin_all ON communications FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Policy per dipendenti: solo i propri dati
CREATE POLICY user_own_data ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY user_tasks ON tasks FOR SELECT USING (
    assigned_user_id = auth.uid() OR 
    assigned_team_id IN (SELECT team_id FROM team_members WHERE user_id = auth.uid())
);
CREATE POLICY user_requests ON requests FOR ALL USING (user_id = auth.uid());
CREATE POLICY user_read_communications ON communications FOR SELECT USING (true);

-- =====================================================
-- VIEWS utili
-- =====================================================

-- Vista tasks con informazioni complete
CREATE OR REPLACE VIEW tasks_complete AS
SELECT 
    t.*,
    c.ragione_sociale as client_name,
    u.nome || ' ' || u.cognome as assigned_user_name,
    tm.nome as assigned_team_name,
    creator.nome || ' ' || creator.cognome as created_by_name
FROM tasks t
LEFT JOIN clients c ON t.client_id = c.id
LEFT JOIN users u ON t.assigned_user_id = u.id
LEFT JOIN teams tm ON t.assigned_team_id = tm.id
LEFT JOIN users creator ON t.created_by = creator.id;

-- Vista team con membri
CREATE OR REPLACE VIEW teams_with_members AS
SELECT 
    t.*,
    json_agg(
        json_build_object(
            'id', u.id,
            'nome', u.nome,
            'cognome', u.cognome,
            'email', u.email,
            'avatar', u.avatar,
            'ruolo_squadra', tm.ruolo_squadra
        )
    ) as membri
FROM teams t
LEFT JOIN team_members tm ON t.id = tm.team_id
LEFT JOIN users u ON tm.user_id = u.id
GROUP BY t.id;

-- =====================================================
-- COMMENTI
-- =====================================================

COMMENT ON TABLE users IS 'Utenti del sistema (admin e dipendenti)';
COMMENT ON TABLE clients IS 'Anagrafica clienti';
COMMENT ON TABLE teams IS 'Squadre di lavoro';
COMMENT ON TABLE team_members IS 'Membri delle squadre';
COMMENT ON TABLE components IS 'Inventario componenti/materiali';
COMMENT ON TABLE tasks IS 'Lavorazioni/Task';
COMMENT ON TABLE task_components IS 'Componenti assegnati alle lavorazioni';
COMMENT ON TABLE requests IS 'Richieste dei dipendenti';
COMMENT ON TABLE communications IS 'Comunicazioni aziendali';

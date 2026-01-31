-- ============================================
-- SISTEMA AUDIT COMPLETO
-- ============================================
-- Traccia TUTTE le operazioni nel sistema per compliance e debug

-- ============================================
-- 1. AUDIT LOG GENERALE (tutto il sistema)
-- ============================================
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Chi e quando
    user_id UUID REFERENCES users(id),
    user_name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Cosa
    entity_type VARCHAR(50) NOT NULL, -- 'kit', 'component', 'client', 'task', 'user', ecc
    entity_id UUID,
    action VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'restore'
    
    -- Dettagli
    description TEXT NOT NULL,
    old_values JSONB, -- Valori prima della modifica
    new_values JSONB, -- Valori dopo la modifica
    
    -- Metadata
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Indici per performance
    CONSTRAINT audit_log_entity_type_check CHECK (entity_type IN (
        'kit', 'kit_item', 'component', 'client', 'task', 'user', 
        'impegno', 'movimento', 'ordine_fornitore', 'preventivo'
    )),
    CONSTRAINT audit_log_action_check CHECK (action IN (
        'create', 'update', 'delete', 'restore', 'state_change', 'assign', 'unassign'
    ))
);

CREATE INDEX idx_audit_log_user ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_log_timestamp ON audit_log(created_at DESC);
CREATE INDEX idx_audit_log_action ON audit_log(action, created_at DESC);

COMMENT ON TABLE audit_log IS 'Log completo di tutte le operazioni nel sistema';

-- ============================================
-- 2. AUDIT KIT SPECIFICO (dettagliato)
-- ============================================
CREATE TABLE IF NOT EXISTS kit_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kit_id UUID NOT NULL REFERENCES kits(id) ON DELETE CASCADE,
    
    -- Chi e quando
    user_id UUID REFERENCES users(id),
    user_name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Tipo operazione
    operation VARCHAR(50) NOT NULL,
    -- 'created', 'updated', 'deleted', 'component_added', 'component_removed', 
    -- 'state_changed', 'assigned', 'delivered'
    
    -- Dettagli
    description TEXT NOT NULL,
    component_id UUID REFERENCES components(id) ON DELETE SET NULL, -- Se riguarda un componente
    component_name VARCHAR(255),
    old_value TEXT,
    new_value TEXT,
    quantity DECIMAL(10,2), -- Se riguarda quantità
    
    -- Extra info
    extra_data JSONB
);

CREATE INDEX idx_kit_audit_kit ON kit_audit(kit_id, created_at DESC);
CREATE INDEX idx_kit_audit_user ON kit_audit(user_id, created_at DESC);
CREATE INDEX idx_kit_audit_operation ON kit_audit(operation, created_at DESC);

COMMENT ON TABLE kit_audit IS 'Storico dettagliato operazioni sui kit';

-- ============================================
-- 3. VISTA MOVIMENTI MAGAZZINO DETTAGLIATA
-- ============================================
CREATE OR REPLACE VIEW v_movimenti_dettagliato AS
SELECT 
    m.id,
    m.data_movimento,
    m.tipo_movimento,
    m.quantita,
    m.causale,
    
    -- Prodotto
    m.prodotto_id,
    c.codice AS prodotto_codice,
    c.nome AS prodotto_nome,
    c.categoria AS prodotto_categoria,
    
    -- Kit (se collegato)
    m.kit_id,
    k.codice_kit,
    k.nome_kit,
    
    -- Ordine fornitore (se collegato)
    m.ordine_fornitore_id,
    of.numero_ordine AS ordine_numero,
    
    -- Lavorazione (se collegato)
    m.lavorazione_id,
    t.titolo AS lavorazione_titolo,
    
    -- Utente
    m.created_by,
    u.nome || ' ' || u.cognome AS created_by_name,
    u.email AS created_by_email,
    
    -- Giacenze
    m.giacenza_prima,
    m.giacenza_dopo,
    
    -- Metadata
    m.created_at
FROM movimenti_magazzino m
LEFT JOIN components c ON m.prodotto_id = c.id
LEFT JOIN kits k ON m.kit_id = k.id
LEFT JOIN ordini_fornitore of ON m.ordine_fornitore_id = of.id
LEFT JOIN tasks t ON m.lavorazione_id = t.id
LEFT JOIN users u ON m.created_by = u.id
ORDER BY m.data_movimento DESC, m.created_at DESC;

COMMENT ON VIEW v_movimenti_dettagliato IS 'Vista completa movimenti magazzino con tutti i dettagli';

-- ============================================
-- 4. VISTA STORICO KIT COMPLETO
-- ============================================
CREATE OR REPLACE VIEW v_kit_storico_completo AS
SELECT 
    ka.id,
    ka.created_at,
    ka.operation,
    ka.description,
    
    -- Kit
    ka.kit_id,
    k.codice_kit,
    k.nome_kit,
    k.stato AS kit_stato,
    
    -- Cliente
    k.cliente_id,
    cl.ragione_sociale AS cliente_nome,
    
    -- Utente che ha fatto l'azione
    ka.user_id,
    ka.user_name,
    
    -- Dettagli componente (se applicabile)
    ka.component_id,
    ka.component_name,
    ka.quantity,
    ka.old_value,
    ka.new_value,
    
    -- Extra
    ka.extra_data
FROM kit_audit ka
LEFT JOIN kits k ON ka.kit_id = k.id
LEFT JOIN clients cl ON k.cliente_id = cl.id
ORDER BY ka.created_at DESC;

COMMENT ON VIEW v_kit_storico_completo IS 'Vista completa storico kit con tutte le operazioni';

-- ============================================
-- 5. TRIGGER PER AUDIT AUTOMATICO KIT
-- ============================================

-- Trigger INSERT kit
CREATE OR REPLACE FUNCTION audit_kit_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
BEGIN
    SELECT nome || ' ' || cognome INTO v_user_name 
    FROM users WHERE id = NEW.created_by;
    
    INSERT INTO kit_audit (
        kit_id, user_id, user_name, operation, description
    ) VALUES (
        NEW.id,
        NEW.created_by,
        v_user_name,
        'created',
        'Kit creato: ' || NEW.codice_kit || ' - ' || COALESCE(NEW.nome_kit, 'Senza nome')
    );
    
    INSERT INTO audit_log (
        user_id, user_name, entity_type, entity_id, action, description, new_values
    ) VALUES (
        NEW.created_by,
        v_user_name,
        'kit',
        NEW.id,
        'create',
        'Kit creato: ' || NEW.codice_kit,
        to_jsonb(NEW)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_audit_kit_insert ON kits;
CREATE TRIGGER trigger_audit_kit_insert
    AFTER INSERT ON kits
    FOR EACH ROW
    EXECUTE FUNCTION audit_kit_insert();

-- Trigger UPDATE kit
CREATE OR REPLACE FUNCTION audit_kit_update()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
    v_changes TEXT := '';
BEGIN
    SELECT nome || ' ' || cognome INTO v_user_name 
    FROM users WHERE id = COALESCE(NEW.created_by, OLD.created_by);
    
    -- Rileva cambiamenti
    IF OLD.nome_kit != NEW.nome_kit THEN
        v_changes := v_changes || 'Nome: "' || OLD.nome_kit || '" → "' || NEW.nome_kit || '"; ';
    END IF;
    
    IF OLD.stato != NEW.stato THEN
        v_changes := v_changes || 'Stato: ' || OLD.stato || ' → ' || NEW.stato || '; ';
        
        INSERT INTO kit_audit (
            kit_id, user_id, user_name, operation, description, old_value, new_value
        ) VALUES (
            NEW.id,
            COALESCE(NEW.created_by, OLD.created_by),
            v_user_name,
            'state_changed',
            'Stato kit modificato',
            OLD.stato,
            NEW.stato
        );
    END IF;
    
    IF v_changes != '' THEN
        INSERT INTO audit_log (
            user_id, user_name, entity_type, entity_id, action, description, old_values, new_values
        ) VALUES (
            COALESCE(NEW.created_by, OLD.created_by),
            v_user_name,
            'kit',
            NEW.id,
            'update',
            'Kit modificato: ' || v_changes,
            to_jsonb(OLD),
            to_jsonb(NEW)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_audit_kit_update ON kits;
CREATE TRIGGER trigger_audit_kit_update
    AFTER UPDATE ON kits
    FOR EACH ROW
    EXECUTE FUNCTION audit_kit_update();

-- Trigger componente aggiunto
CREATE OR REPLACE FUNCTION audit_kit_item_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
    v_kit_code TEXT;
BEGIN
    SELECT nome || ' ' || cognome INTO v_user_name 
    FROM users WHERE id = NEW.aggiunto_da;
    
    SELECT codice_kit INTO v_kit_code FROM kits WHERE id = NEW.kit_id;
    
    INSERT INTO kit_audit (
        kit_id, user_id, user_name, operation, description,
        component_id, component_name, quantity
    ) VALUES (
        NEW.kit_id,
        NEW.aggiunto_da,
        v_user_name,
        'component_added',
        'Componente aggiunto al kit ' || v_kit_code,
        NEW.prodotto_id,
        NEW.prodotto_nome,
        NEW.quantita
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_audit_kit_item_insert ON kit_items;
CREATE TRIGGER trigger_audit_kit_item_insert
    AFTER INSERT ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION audit_kit_item_insert();

-- Trigger componente rimosso
CREATE OR REPLACE FUNCTION audit_kit_item_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
    v_kit_code TEXT;
BEGIN
    SELECT nome || ' ' || cognome INTO v_user_name 
    FROM users WHERE id = OLD.aggiunto_da;
    
    SELECT codice_kit INTO v_kit_code FROM kits WHERE id = OLD.kit_id;
    
    INSERT INTO kit_audit (
        kit_id, user_id, user_name, operation, description,
        component_id, component_name, quantity
    ) VALUES (
        OLD.kit_id,
        OLD.aggiunto_da,
        v_user_name,
        'component_removed',
        'Componente rimosso dal kit ' || v_kit_code,
        OLD.prodotto_id,
        OLD.prodotto_nome,
        OLD.quantita
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_audit_kit_item_delete ON kit_items;
CREATE TRIGGER trigger_audit_kit_item_delete
    BEFORE DELETE ON kit_items
    FOR EACH ROW
    EXECUTE FUNCTION audit_kit_item_delete();

-- ============================================
-- 6. FUNZIONE UTILITY: Get Audit Kit
-- ============================================
CREATE OR REPLACE FUNCTION get_kit_audit(p_kit_id UUID, p_limit INT DEFAULT 50)
RETURNS TABLE (
    audit_timestamp TIMESTAMPTZ,
    operation VARCHAR,
    description TEXT,
    user_name VARCHAR,
    component_name VARCHAR,
    quantity DECIMAL,
    old_value TEXT,
    new_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ka.created_at,
        ka.operation,
        ka.description,
        ka.user_name,
        ka.component_name,
        ka.quantity,
        ka.old_value,
        ka.new_value
    FROM kit_audit ka
    WHERE ka.kit_id = p_kit_id
    ORDER BY ka.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VERIFICA
-- ============================================
SELECT '✅ Sistema audit completo creato!' AS status;

-- Mostra tabelle create
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('audit_log', 'kit_audit')
ORDER BY table_name;

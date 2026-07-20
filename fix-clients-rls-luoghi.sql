-- =====================================================
-- Fix: aggiunge 'luogo' al check constraint tipo_cliente
-- e assicura comune_id + permessi RLS
-- =====================================================

-- 1. Rimuovi il vecchio constraint tipo_cliente
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_tipo_cliente_check;

-- 2. Ricrealo includendo 'luogo'
ALTER TABLE clients ADD CONSTRAINT clients_tipo_cliente_check
    CHECK (tipo_cliente IN (
        'privato', 'azienda', 'associazione', 'condominio',
        'comune', 'scuola', 'struttura', 'luogo',
        'amministratore_condominio'
    ));

-- 3. Assicura che comune_id esista
ALTER TABLE clients
    ADD COLUMN IF NOT EXISTS comune_id uuid REFERENCES clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_clients_comune_id ON clients(comune_id);

-- 4. RLS permissiva per autenticati
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clients_authenticated_write" ON clients;
DROP POLICY IF EXISTS "clients_authenticated_select" ON clients;
DROP POLICY IF EXISTS "clients_admin_all" ON clients;
DROP POLICY IF EXISTS "clients_select_all" ON clients;

CREATE POLICY "clients_authenticated_select" ON clients
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "clients_authenticated_write" ON clients
    FOR ALL
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

SELECT 'Fix completato: tipo_cliente ora include luogo' AS status;

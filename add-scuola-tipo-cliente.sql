-- =====================================================
-- Aggiorna il CHECK constraint tipo_cliente
-- Aggiunge il tipo 'scuola'
-- =====================================================

ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_tipo_cliente_check;

ALTER TABLE clients
ADD CONSTRAINT clients_tipo_cliente_check
CHECK (tipo_cliente IN (
    'privato',
    'azienda',
    'condominio',
    'associazione',
    'comune',
    'amministratore_condominio',
    'scuola'
));

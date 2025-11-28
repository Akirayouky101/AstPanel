-- =====================================================
-- Migration: Aggiungi nuovi tipi cliente e campi amministratore
-- Data: 28 novembre 2025
-- =====================================================

-- 1. Aggiorna il constraint per includere i nuovi tipi
ALTER TABLE clients 
DROP CONSTRAINT IF EXISTS clients_tipo_cliente_check;

ALTER TABLE clients 
ADD CONSTRAINT clients_tipo_cliente_check 
CHECK (tipo_cliente IN ('azienda', 'privato', 'condominio', 'associazione', 'comune'));

-- 2. Aggiungi campi per amministratore/referente
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS nome_referente VARCHAR(100),
ADD COLUMN IF NOT EXISTS cognome_referente VARCHAR(100),
ADD COLUMN IF NOT EXISTS telefono_referente VARCHAR(50),
ADD COLUMN IF NOT EXISTS email_referente VARCHAR(255);

-- 3. Aggiungi campi specifici per condomini
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS nome_amministratore VARCHAR(100),
ADD COLUMN IF NOT EXISTS cognome_amministratore VARCHAR(100),
ADD COLUMN IF NOT EXISTS telefono_amministratore VARCHAR(50),
ADD COLUMN IF NOT EXISTS email_amministratore VARCHAR(255),
ADD COLUMN IF NOT EXISTS pec_amministratore VARCHAR(255);

-- 4. Aggiungi commenti descrittivi
COMMENT ON COLUMN clients.tipo_cliente IS 'Tipo di cliente: azienda, privato, condominio, associazione, comune';
COMMENT ON COLUMN clients.nome_referente IS 'Nome del referente (per aziende, associazioni, comuni)';
COMMENT ON COLUMN clients.cognome_referente IS 'Cognome del referente (per aziende, associazioni, comuni)';
COMMENT ON COLUMN clients.telefono_referente IS 'Telefono del referente';
COMMENT ON COLUMN clients.email_referente IS 'Email del referente';
COMMENT ON COLUMN clients.nome_amministratore IS 'Nome amministratore condominiale';
COMMENT ON COLUMN clients.cognome_amministratore IS 'Cognome amministratore condominiale';
COMMENT ON COLUMN clients.telefono_amministratore IS 'Telefono amministratore condominiale';
COMMENT ON COLUMN clients.email_amministratore IS 'Email amministratore condominiale';
COMMENT ON COLUMN clients.pec_amministratore IS 'PEC amministratore condominiale';

-- Log della migrazione
DO $$
BEGIN
    RAISE NOTICE 'Nuovi tipi cliente e campi amministratore/referente aggiunti con successo';
END $$;

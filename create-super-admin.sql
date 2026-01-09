-- =====================================================
-- AST PANEL - Crea Super Admin Protetto
-- =====================================================
-- Questo script crea un amministratore che NON può essere cancellato
-- =====================================================

-- 1. Aggiungi colonna PIN alla tabella users se non esiste
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_code VARCHAR(10);

-- 1b. Verifica e aggiorna il constraint ruolo per includere 'tecnico'
DO $$ 
BEGIN
    -- Rimuovi il vecchio constraint se esiste
    ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;
    
    -- Crea il nuovo constraint con tutti i ruoli
    ALTER TABLE users ADD CONSTRAINT users_ruolo_check 
    CHECK (ruolo IN ('admin', 'dipendente', 'tecnico'));
EXCEPTION
    WHEN OTHERS THEN
        -- Se ci sono errori, continua comunque
        RAISE NOTICE 'Constraint già presente o errore: %', SQLERRM;
END $$;

-- 2. Inserisci il Super Admin con un ID fisso e riconoscibile
INSERT INTO users (
    id,
    email, 
    nome, 
    cognome, 
    ruolo, 
    telefono, 
    stato,
    auth_id,
    pin_code
)
VALUES 
    (
        '00000000-0000-0000-0000-000000000001'::UUID,  -- ID FISSO per il super admin
        'diegomarruchi@outlook.it', 
        'Diego', 
        'Marruchi', 
        'tecnico', 
        '3896136963', 
        'attivo',
        '0536c4f6-e377-4e81-ab81-95e14a2214d7'::UUID,  -- Il tuo auth_id di Supabase
        '4658101'  -- PIN per sicurezza extra
    )
ON CONFLICT (id) DO UPDATE SET
    auth_id = EXCLUDED.auth_id,
    email = EXCLUDED.email,
    nome = EXCLUDED.nome,
    cognome = EXCLUDED.cognome,
    telefono = EXCLUDED.telefono,
    pin_code = EXCLUDED.pin_code,
    updated_at = NOW();

-- 2. Crea funzione che blocca la cancellazione del super admin
CREATE OR REPLACE FUNCTION prevent_superadmin_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Impedisci cancellazione del super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE ELIMINARE IL SUPER ADMIN! Questo utente è protetto e non può essere rimosso.';
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 3. Crea trigger sulla tabella users
DROP TRIGGER IF EXISTS protect_superadmin ON users;
CREATE TRIGGER protect_superadmin
    BEFORE DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION prevent_superadmin_deletion();

-- 4. Crea funzione che blocca la modifica del ruolo del super admin
CREATE OR REPLACE FUNCTION prevent_superadmin_role_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Impedisci modifica ruolo del super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID AND NEW.ruolo != 'admin' THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE IL RUOLO DEL SUPER ADMIN!';
    END IF;
    
    -- Impedisci disattivazione del super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID AND NEW.stato != 'attivo' THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE DISATTIVARE IL SUPER ADMIN!';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Crea trigger per protezione ruolo
DROP TRIGGER IF EXISTS protect_superadmin_role ON users;
CREATE TRIGGER protect_superadmin_role
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION prevent_superadmin_role_change();

-- Verifica che il super admin sia stato creato
SELECT 
    id,
    email,
    nome,
    cognome,
    ruolo,
    stato,
    auth_id,
    '✅ SUPER ADMIN PROTETTO CREATO CON SUCCESSO!' as status
FROM users 
WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;

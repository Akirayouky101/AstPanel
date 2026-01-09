-- =====================================================
-- FIX TRIGGER SUPER ADMIN - Permetti cambio first_login
-- =====================================================
-- Il trigger attuale blocca QUALSIASI UPDATE sul super admin
-- Dobbiamo permettere l'aggiornamento di first_login
-- =====================================================

-- 1. Elimina il vecchio trigger e funzione
DROP TRIGGER IF EXISTS protect_superadmin_role ON users;
DROP FUNCTION IF EXISTS prevent_superadmin_role_change();

-- 2. Crea nuova funzione più intelligente
CREATE OR REPLACE FUNCTION prevent_superadmin_role_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Controlla solo se è il super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID THEN
        
        -- Impedisci modifica ruolo
        IF NEW.ruolo != OLD.ruolo THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE IL RUOLO DEL SUPER ADMIN!';
        END IF;
        
        -- Impedisci disattivazione
        IF NEW.stato != 'attivo' THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE DISATTIVARE IL SUPER ADMIN!';
        END IF;
        
        -- Impedisci rimozione auth_id
        IF NEW.auth_id IS NULL OR NEW.auth_id != OLD.auth_id THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE L''AUTH_ID DEL SUPER ADMIN!';
        END IF;
        
        -- PERMETTI modifica di altri campi come first_login, updated_at, ecc.
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Ricrea il trigger
CREATE TRIGGER protect_superadmin_role
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION prevent_superadmin_role_change();

-- 4. Test: aggiorna first_login (dovrebbe funzionare)
UPDATE users
SET first_login = false
WHERE id = '00000000-0000-0000-0000-000000000001';

-- 5. Verifica
SELECT 
    id,
    email,
    nome,
    cognome,
    ruolo,
    stato,
    first_login,
    auth_id,
    '✅ Trigger aggiornato - first_login modificabile' as status
FROM users
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Messaggio di conferma
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Trigger super admin aggiornato!';
    RAISE NOTICE '🔒 Protezioni attive:';
    RAISE NOTICE '  - ❌ Ruolo NON modificabile';
    RAISE NOTICE '  - ❌ Stato NON modificabile (deve essere attivo)';
    RAISE NOTICE '  - ❌ Auth ID NON modificabile';
    RAISE NOTICE '  - ✅ first_login MODIFICABILE';
    RAISE NOTICE '  - ✅ Altri campi MODIFICABILI';
END $$;

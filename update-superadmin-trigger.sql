-- =====================================================
-- AGGIORNA TRIGGER SUPER ADMIN - Proteggi ruolo 'titolare'
-- =====================================================

-- Aggiorna la funzione che blocca la modifica del ruolo del super admin
CREATE OR REPLACE FUNCTION prevent_superadmin_role_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Impedisci modifica ruolo del super admin (deve restare 'titolare')
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID AND NEW.ruolo != 'titolare' THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE IL RUOLO DEL SUPER ADMIN! Deve restare Titolare.';
    END IF;
    
    -- Impedisci disattivazione del super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID AND NEW.stato != 'attivo' THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE DISATTIVARE IL SUPER ADMIN!';
    END IF;
    
    -- Impedisci modifica auth_id del super admin
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID AND NEW.auth_id != OLD.auth_id THEN
        RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE L''AUTH_ID DEL SUPER ADMIN!';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ TRIGGER SUPER ADMIN AGGIORNATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '🛡️  Protezioni attive:';
    RAISE NOTICE '  - Ruolo: Deve restare TITOLARE';
    RAISE NOTICE '  - Stato: Deve restare ATTIVO';
    RAISE NOTICE '  - Auth ID: Non può essere modificato';
    RAISE NOTICE '';
END $$;

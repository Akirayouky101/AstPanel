-- =====================================================
-- DISABILITA TRIGGER handle_new_user TEMPORANEAMENTE
-- =====================================================
-- Questo trigger prova a inserire in user_profiles
-- che non esiste o non è configurato correttamente
-- =====================================================

-- Disabilita il trigger
ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_created;

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ Trigger on_auth_user_created DISABILITATO';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Ora puoi creare utenti auth senza errori!';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  RICORDA: Ri-abilitare dopo setup con:';
    RAISE NOTICE '   ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created;';
    RAISE NOTICE '';
    RAISE NOTICE 'Oppure elimina completamente il trigger se non serve:';
    RAISE NOTICE '   DROP TRIGGER on_auth_user_created ON auth.users;';
END $$;

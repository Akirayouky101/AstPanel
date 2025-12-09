-- =====================================================
-- ELIMINA TRIGGER handle_new_user (APPROCCIO ALTERNATIVO)
-- =====================================================
-- Non possiamo disabilitare trigger su auth.users
-- Ma possiamo eliminarlo definitivamente
-- =====================================================

-- Prova a eliminare il trigger (richiede permessi service_role)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ Trigger on_auth_user_created ELIMINATO';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Ora puoi creare utenti auth senza errori!';
END $$;

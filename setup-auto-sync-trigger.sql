-- =====================================================
-- AUTO-SYNC TRIGGER - Crea automaticamente utente in public.users
-- quando viene creato in auth.users
-- =====================================================

-- Function: auto-crea utente in public.users dopo creazione auth
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    v_nome TEXT;
    v_cognome TEXT;
    v_ruolo TEXT;
BEGIN
    -- Estrai metadati dall'utente auth (se presenti)
    v_nome := COALESCE(NEW.raw_user_meta_data->>'nome', 'Utente');
    v_cognome := COALESCE(NEW.raw_user_meta_data->>'cognome', 'Nuovo');
    v_ruolo := COALESCE(NEW.raw_user_meta_data->>'ruolo', 'dipendente');
    
    -- Inserisci in public.users SOLO se non esiste già
    INSERT INTO public.users (
        id,
        auth_id,
        email,
        nome,
        cognome,
        ruolo,
        stato,
        first_login,
        created_at
    ) VALUES (
        gen_random_uuid(),
        NEW.id,
        NEW.email,
        v_nome,
        v_cognome,
        v_ruolo,
        'attivo',
        true,
        NOW()
    )
    ON CONFLICT (auth_id) DO NOTHING; -- Evita duplicati
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: esegui dopo inserimento in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '✅ AUTO-SYNC TRIGGER INSTALLATO!';
    RAISE NOTICE '✅ ========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Da ora in poi:';
    RAISE NOTICE '  1️⃣ Creazione utente in auth.users';
    RAISE NOTICE '  2️⃣ ➡️ AUTO-CREA entry in public.users';
    RAISE NOTICE '  3️⃣ ✅ Sincronizzazione automatica!';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ Per utenti già esistenti solo in auth.users,';
    RAISE NOTICE '   esegui check-all-users-sync.sql e sincronizza manualmente';
    RAISE NOTICE '';
END $$;

-- Fix v2: hashing del PIN indipendente da dove e' installato pgcrypto.
-- Le funzioni helper trovano lo schema di pgcrypto a runtime (su Supabase e' "extensions");
-- se pgcrypto non c'e' usano sha256 + salt casuale (funzioni core di PostgreSQL).

CREATE OR REPLACE FUNCTION public.pin_sezioni_hash(p_pin TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_schema TEXT;
    v_hash TEXT;
    v_salt TEXT;
BEGIN
    SELECT n.nspname INTO v_schema
    FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'pgcrypto';
    IF v_schema IS NOT NULL THEN
        EXECUTE format('SELECT %I.crypt($1, %I.gen_salt(''bf'', 10))', v_schema, v_schema) INTO v_hash USING p_pin;
        RETURN v_hash;
    END IF;
    v_salt := replace(gen_random_uuid()::TEXT, '-', '');
    RETURN 'sha256$' || v_salt || '$' || encode(sha256(convert_to(v_salt || p_pin, 'UTF8')), 'hex');
END;
$$;
REVOKE ALL ON FUNCTION public.pin_sezioni_hash(TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.pin_sezioni_check(p_pin TEXT, p_hash TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_schema TEXT;
    v_calc TEXT;
    v_parts TEXT[];
BEGIN
    IF p_pin IS NULL OR p_hash IS NULL THEN RETURN FALSE; END IF;
    IF p_hash LIKE 'sha256$%' THEN
        v_parts := string_to_array(p_hash, '$');
        RETURN encode(sha256(convert_to(v_parts[2] || p_pin, 'UTF8')), 'hex') = v_parts[3];
    END IF;
    SELECT n.nspname INTO v_schema
    FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'pgcrypto';
    IF v_schema IS NULL THEN RETURN FALSE; END IF;
    EXECUTE format('SELECT %I.crypt($1, $2)', v_schema) INTO v_calc USING p_pin, p_hash;
    RETURN v_calc = p_hash;
END;
$$;
REVOKE ALL ON FUNCTION public.pin_sezioni_check(TEXT, TEXT) FROM PUBLIC;

-- Verifica il PIN inserito: sblocca per 30 minuti, blocca 10 minuti dopo 5 errori
CREATE OR REPLACE FUNCTION public.verifica_pin_sezioni(p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    u public.users;
    p public.users_pin_sezioni;
    v_max_tentativi CONSTANT INTEGER := 5;
BEGIN
    u := public.pin_sezioni_me();
    IF u.id IS NULL OR NOT u.pin_sezioni_attivo OR u.stato <> 'attivo' THEN
        RETURN jsonb_build_object('ok', false, 'motivo', 'non_abilitato');
    END IF;
    SELECT * INTO p FROM public.users_pin_sezioni WHERE user_id = u.id FOR UPDATE;
    IF p.user_id IS NULL THEN
        RETURN jsonb_build_object('ok', false, 'motivo', 'pin_non_impostato');
    END IF;
    IF p.bloccato_fino IS NOT NULL AND p.bloccato_fino > NOW() THEN
        RETURN jsonb_build_object('ok', false, 'motivo', 'bloccato', 'bloccato_secondi', EXTRACT(EPOCH FROM (p.bloccato_fino - NOW()))::INTEGER);
    END IF;
    IF public.pin_sezioni_check(p_pin, p.pin_hash) THEN
        UPDATE public.users_pin_sezioni
           SET tentativi = 0, bloccato_fino = NULL, verificato_fino = NOW() + INTERVAL '30 minutes'
         WHERE user_id = u.id;
        RETURN jsonb_build_object('ok', true, 'secondi_residui', 1800);
    END IF;
    UPDATE public.users_pin_sezioni
       SET tentativi = tentativi + 1,
           bloccato_fino = CASE WHEN tentativi + 1 >= v_max_tentativi THEN NOW() + INTERVAL '10 minutes' END,
           verificato_fino = NULL
     WHERE user_id = u.id
     RETURNING * INTO p;
    IF p.bloccato_fino IS NOT NULL THEN
        UPDATE public.users_pin_sezioni SET tentativi = 0 WHERE user_id = u.id;
        RETURN jsonb_build_object('ok', false, 'motivo', 'bloccato', 'bloccato_secondi', 600);
    END IF;
    RETURN jsonb_build_object('ok', false, 'motivo', 'errato', 'tentativi_residui', v_max_tentativi - p.tentativi);
END;
$$;
GRANT EXECUTE ON FUNCTION public.verifica_pin_sezioni(TEXT) TO authenticated;

-- Imposta flag e PIN di un utente (solo amministratori). p_pin NULL con p_attivo = true mantiene il PIN esistente.
CREATE OR REPLACE FUNCTION public.set_pin_sezioni(p_user_id UUID, p_attivo BOOLEAN, p_pin TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_admin public.users;
    v_ha_pin BOOLEAN;
BEGIN
    v_admin := public.pin_sezioni_me();
    IF v_admin.id IS NULL OR lower(COALESCE(v_admin.ruolo, '')) NOT IN ('titolare', 'segreteria', 'tecnico', 'admin', 'amministratore') THEN
        RAISE EXCEPTION 'Permessi amministrativi richiesti' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Utente non trovato';
    END IF;

    IF NOT p_attivo THEN
        UPDATE public.users SET pin_sezioni_attivo = FALSE WHERE id = p_user_id;
        DELETE FROM public.users_pin_sezioni WHERE user_id = p_user_id;
        RETURN jsonb_build_object('attivo', false);
    END IF;

    IF p_pin IS NOT NULL THEN
        IF p_pin !~ '^\d{4,8}$' THEN
            RAISE EXCEPTION 'Il PIN deve avere da 4 a 8 cifre';
        END IF;
        INSERT INTO public.users_pin_sezioni (user_id, pin_hash, tentativi, bloccato_fino, verificato_fino, updated_by, updated_at)
        VALUES (p_user_id, public.pin_sezioni_hash(p_pin), 0, NULL, NULL, v_admin.id, NOW())
        ON CONFLICT (user_id) DO UPDATE
            SET pin_hash = EXCLUDED.pin_hash, tentativi = 0, bloccato_fino = NULL, verificato_fino = NULL,
                updated_by = EXCLUDED.updated_by, updated_at = NOW();
    END IF;

    SELECT EXISTS (SELECT 1 FROM public.users_pin_sezioni WHERE user_id = p_user_id) INTO v_ha_pin;
    IF NOT v_ha_pin THEN
        RAISE EXCEPTION 'Inserisci un PIN per attivare l''accesso alle sezioni protette';
    END IF;
    UPDATE public.users SET pin_sezioni_attivo = TRUE WHERE id = p_user_id;
    RETURN jsonb_build_object('attivo', true);
END;
$$;
GRANT EXECUTE ON FUNCTION public.set_pin_sezioni(UUID, BOOLEAN, TEXT) TO authenticated;

-- Diagnostica: dove sta pgcrypto e prova di hash/verifica (deve dare hash_ok = true)
SELECT e.extname, n.nspname AS schema FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace WHERE e.extname = 'pgcrypto';
SELECT public.pin_sezioni_check('1234', public.pin_sezioni_hash('1234')) AS hash_ok;

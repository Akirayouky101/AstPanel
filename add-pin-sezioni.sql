-- ============================================================
-- PIN SEZIONI PROTETTE (es. Contabilità)
-- - users.pin_sezioni_attivo: flag "PIN Attivo" gestito da Gestione utenti
-- - users_pin_sezioni: hash bcrypt del PIN, tentativi, blocco e scadenza
--   verifica. Nessuna policy RLS => il client non la legge mai, si usa
--   solo tramite le RPC SECURITY DEFINER qui sotto.
-- - pin_sezioni_ok(): usata nelle policy RLS delle tabelle protette.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Su Supabase pgcrypto sta nello schema "extensions": le funzioni che usano crypt/gen_salt lo includono nel search_path.

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS pin_sezioni_attivo BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN public.users.pin_sezioni_attivo IS 'Se true l''utente può accedere alle sezioni protette da PIN (Contabilità)';

CREATE TABLE IF NOT EXISTS public.users_pin_sezioni (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    pin_hash TEXT NOT NULL,
    tentativi INTEGER NOT NULL DEFAULT 0,
    bloccato_fino TIMESTAMPTZ,
    verificato_fino TIMESTAMPTZ,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.users_pin_sezioni ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.users_pin_sezioni FROM anon, authenticated;

-- Profilo dell'utente loggato
CREATE OR REPLACE FUNCTION public.pin_sezioni_me()
RETURNS public.users
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT u.* FROM public.users u WHERE u.auth_id = auth.uid() LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.pin_sezioni_me() FROM PUBLIC;

-- True se l'utente loggato ha il flag e ha verificato il PIN di recente
CREATE OR REPLACE FUNCTION public.pin_sezioni_ok()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.users u
        JOIN public.users_pin_sezioni p ON p.user_id = u.id
        WHERE u.auth_id = auth.uid()
          AND u.pin_sezioni_attivo
          AND u.stato = 'attivo'
          AND p.verificato_fino > NOW()
    );
$$;
GRANT EXECUTE ON FUNCTION public.pin_sezioni_ok() TO authenticated;

-- Stato per la UI: abilitato? verificato? secondi residui? bloccato?
CREATE OR REPLACE FUNCTION public.pin_sezioni_stato()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    u public.users;
    p public.users_pin_sezioni;
BEGIN
    u := public.pin_sezioni_me();
    IF u.id IS NULL THEN
        RETURN jsonb_build_object('abilitato', false, 'motivo', 'utente_non_trovato');
    END IF;
    SELECT * INTO p FROM public.users_pin_sezioni WHERE user_id = u.id;
    IF NOT u.pin_sezioni_attivo OR u.stato <> 'attivo' THEN
        RETURN jsonb_build_object('abilitato', false, 'motivo', 'non_abilitato');
    END IF;
    IF p.user_id IS NULL THEN
        RETURN jsonb_build_object('abilitato', false, 'motivo', 'pin_non_impostato');
    END IF;
    RETURN jsonb_build_object(
        'abilitato', true,
        'verificato', COALESCE(p.verificato_fino > NOW(), false),
        'secondi_residui', GREATEST(0, EXTRACT(EPOCH FROM (p.verificato_fino - NOW()))::INTEGER),
        'bloccato_secondi', GREATEST(0, COALESCE(EXTRACT(EPOCH FROM (p.bloccato_fino - NOW()))::INTEGER, 0))
    );
END;
$$;
GRANT EXECUTE ON FUNCTION public.pin_sezioni_stato() TO authenticated;

-- Verifica il PIN inserito: sblocca per 30 minuti, blocca 10 minuti dopo 5 errori
CREATE OR REPLACE FUNCTION public.verifica_pin_sezioni(p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
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
    IF p_pin IS NOT NULL AND p.pin_hash = crypt(p_pin, p.pin_hash) THEN
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

-- Chiude la sessione PIN (logout dalla sezione)
CREATE OR REPLACE FUNCTION public.chiudi_pin_sezioni()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    UPDATE public.users_pin_sezioni SET verificato_fino = NULL
    WHERE user_id = (SELECT id FROM public.users WHERE auth_id = auth.uid());
$$;
GRANT EXECUTE ON FUNCTION public.chiudi_pin_sezioni() TO authenticated;

-- Imposta flag e PIN di un utente (solo amministratori: titolare, segreteria, tecnico)
-- p_pin NULL con p_attivo = true mantiene il PIN esistente.
CREATE OR REPLACE FUNCTION public.set_pin_sezioni(p_user_id UUID, p_attivo BOOLEAN, p_pin TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
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
        VALUES (p_user_id, crypt(p_pin, gen_salt('bf', 10)), 0, NULL, NULL, v_admin.id, NOW())
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

-- ------------------------------------------------------------
-- Contabilità: accesso solo con flag + PIN verificato
-- ------------------------------------------------------------
DROP POLICY IF EXISTS contabilita_movimenti_all ON public.contabilita_movimenti;
CREATE POLICY contabilita_movimenti_all ON public.contabilita_movimenti
    FOR ALL TO authenticated USING (public.pin_sezioni_ok()) WITH CHECK (public.pin_sezioni_ok());

DROP POLICY IF EXISTS contabilita_ricorrenti_all ON public.contabilita_ricorrenti;
CREATE POLICY contabilita_ricorrenti_all ON public.contabilita_ricorrenti
    FOR ALL TO authenticated USING (public.pin_sezioni_ok()) WITH CHECK (public.pin_sezioni_ok());

DROP POLICY IF EXISTS contabilita_saldi_all ON public.contabilita_saldi;
CREATE POLICY contabilita_saldi_all ON public.contabilita_saldi
    FOR ALL TO authenticated USING (public.pin_sezioni_ok()) WITH CHECK (public.pin_sezioni_ok());

COMMENT ON TABLE public.users_pin_sezioni IS 'Hash PIN sezioni protette per utente; accesso solo via RPC';

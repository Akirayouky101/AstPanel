-- =====================================================
-- FIX TRIGGER SUPER ADMIN v2
-- Il trigger precedente alzava l'errore su QUALSIASI update della riga del
-- super admin se ruolo/stato non erano esattamente 'titolare'/'attivo',
-- bloccando anche modifiche ad altri campi (es. pin_sezioni_attivo).
-- Ora blocca solo i cambi effettivi, confrontando senza distinzione di maiuscole.
-- =====================================================

CREATE OR REPLACE FUNCTION public.prevent_superadmin_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.id = '00000000-0000-0000-0000-000000000001'::UUID THEN
        IF lower(COALESCE(NEW.ruolo, '')) <> lower(COALESCE(OLD.ruolo, ''))
           AND lower(COALESCE(NEW.ruolo, '')) <> 'titolare' THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE IL RUOLO DEL SUPER ADMIN! Deve restare Titolare.';
        END IF;
        IF lower(COALESCE(NEW.stato, '')) <> lower(COALESCE(OLD.stato, ''))
           AND lower(COALESCE(NEW.stato, '')) <> 'attivo' THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE DISATTIVARE IL SUPER ADMIN!';
        END IF;
        IF NEW.auth_id IS DISTINCT FROM OLD.auth_id AND OLD.auth_id IS NOT NULL THEN
            RAISE EXCEPTION '🚫 IMPOSSIBILE MODIFICARE L''AUTH_ID DEL SUPER ADMIN!';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_superadmin_role ON public.users;
CREATE TRIGGER protect_superadmin_role
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.prevent_superadmin_role_change();

-- Normalizza il ruolo del super admin in minuscolo (le pagine confrontano in lowercase)
UPDATE public.users SET ruolo = 'titolare'
WHERE id = '00000000-0000-0000-0000-000000000001'::UUID AND ruolo <> 'titolare';

SELECT id, nome, ruolo, stato, pin_sezioni_attivo
FROM public.users WHERE id = '00000000-0000-0000-0000-000000000001'::UUID;

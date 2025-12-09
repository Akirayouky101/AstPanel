-- =====================================================
-- DISABILITA RLS TEMPORANEAMENTE PER SETUP
-- =====================================================
-- Disabilita RLS su tutte le tabelle per permettere setup
-- DA RI-ABILITARE dopo creazione primo admin!
-- =====================================================

-- Disabilita RLS su tutte le tabelle public
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.components DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_components DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.timbrature DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.timbrature_modifiche DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_availability DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_history DISABLE ROW LEVEL SECURITY;

-- Verifica
DO $$
BEGIN
    RAISE NOTICE '✅ RLS DISABILITATO su tutte le tabelle';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE: Questo è TEMPORANEO per il setup!';
    RAISE NOTICE '   Dopo aver creato il primo admin:';
    RAISE NOTICE '   1. Vai su first-setup.html e crea admin';
    RAISE NOTICE '   2. Esegui migrations/enable-supabase-auth-universal.sql';
    RAISE NOTICE '   3. Ri-abilita RLS per sicurezza';
END $$;

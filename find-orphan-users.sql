-- =====================================================
-- TROVA E PULISCI UTENTI ORFANI SPECIFICI
-- =====================================================

-- 1. Verifica quale auth_id NON ha corrispondenza in public.users
SELECT 
    au.id as auth_id,
    au.email,
    au.created_at,
    '❌ ORPHAN - Esiste solo in auth.users' as status
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu
    WHERE pu.auth_id = au.id
)
ORDER BY au.created_at DESC;

-- 2. Verifica se esiste l'utente problematico specifico
SELECT 
    'auth.users' as tabella,
    id::text as id,
    email,
    created_at
FROM auth.users
WHERE id = 'c0d0a351-f4ab-47a8-b5d3-8c3e56227b0e'

UNION ALL

SELECT 
    'public.users' as tabella,
    auth_id::text as id,
    email,
    created_at
FROM public.users
WHERE auth_id = 'c0d0a351-f4ab-47a8-b5d3-8c3e56227b0e';

-- 3. Elimina l'utente orfano specifico
DELETE FROM auth.users 
WHERE id = 'c0d0a351-f4ab-47a8-b5d3-8c3e56227b0e'
AND NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE auth_id = 'c0d0a351-f4ab-47a8-b5d3-8c3e56227b0e'
);

-- 4. OPPURE elimina TUTTI gli utenti orfani (tranne super admin)
-- ATTENZIONE: Questo eliminerà tutti gli utenti in auth.users che non hanno corrispondenza in public.users
/*
DO $$ 
DECLARE
    orphan_record RECORD;
    deleted_count INTEGER := 0;
BEGIN
    FOR orphan_record IN 
        SELECT au.id, au.email
        FROM auth.users au
        WHERE NOT EXISTS (
            SELECT 1 FROM public.users pu
            WHERE pu.auth_id = au.id
        )
        -- Non eliminare il super admin
        AND au.id != '0536c4f6-e377-4e81-ab81-95e14a2214d7'
    LOOP
        DELETE FROM auth.users WHERE id = orphan_record.id;
        deleted_count := deleted_count + 1;
        RAISE NOTICE 'Eliminato utente orfano: % (ID: %)', orphan_record.email, orphan_record.id;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Eliminati % utenti orfani', deleted_count;
END $$;
*/

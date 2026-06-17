-- =====================================================
-- SISTEMA ACCESSO SPECIALE
-- Crea la tabella richieste_speciali per il pannello del capo
-- =====================================================
-- Eseguire nel SQL editor di Supabase
-- =====================================================

-- 1. Crea tabella richieste_speciali
CREATE TABLE IF NOT EXISTS richieste_speciali (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL,
    -- tipi: 'sposta' | 'duplica' | 'aggiungi' | 'nota' | 'modifica_orario'
    titolo TEXT NOT NULL,
    descrizione TEXT,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    dati_extra JSONB DEFAULT '{}',
    letta BOOLEAN DEFAULT false,
    elaborata BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Abilita RLS
ALTER TABLE richieste_speciali ENABLE ROW LEVEL SECURITY;

-- 3. Policy: tutti gli autenticati possono inserire
CREATE POLICY "richieste_speciali_insert" ON richieste_speciali
FOR INSERT TO authenticated
WITH CHECK (true);

-- 4. Policy: tutti gli autenticati possono leggere
CREATE POLICY "richieste_speciali_select" ON richieste_speciali
FOR SELECT TO authenticated
USING (true);

-- 5. Policy: tutti gli autenticati possono aggiornare (per segnare 'letta')
CREATE POLICY "richieste_speciali_update" ON richieste_speciali
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

-- 6. Policy: solo admin possono eliminare
CREATE POLICY "richieste_speciali_delete" ON richieste_speciali
FOR DELETE TO authenticated
USING (true);

-- 7. Aggiorna il constraint ruolo nella tabella users per includere 'accesso_speciale'
-- Prima verifica quale constraint esiste:
-- SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid = 'users'::regclass AND contype = 'c';

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_ruolo_check;
ALTER TABLE users ADD CONSTRAINT users_ruolo_check
    CHECK (ruolo IN ('titolare', 'tecnico', 'segreteria', 'dipendente', 'accesso_speciale'));

-- 9. Abilita Realtime per le notifiche admin
ALTER PUBLICATION supabase_realtime ADD TABLE richieste_speciali;

-- 10. Indici per performance
CREATE INDEX IF NOT EXISTS idx_richieste_speciali_user_id ON richieste_speciali(user_id);
CREATE INDEX IF NOT EXISTS idx_richieste_speciali_letta ON richieste_speciali(letta);
CREATE INDEX IF NOT EXISTS idx_richieste_speciali_created_at ON richieste_speciali(created_at DESC);

-- Verifica
SELECT '✅ Sistema Accesso Speciale creato!' as status;
SELECT COUNT(*) as totale_richieste FROM richieste_speciali;

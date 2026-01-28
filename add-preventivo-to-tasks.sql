-- =====================================================
-- COLLEGA PREVENTIVI A LAVORAZIONI (TASKS)
-- =====================================================
-- Aggiunge campo preventivo_id per tracciare da quale 
-- preventivo è stata generata la lavorazione
-- =====================================================

-- 1. Aggiungi colonna preventivo_id a tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS preventivo_id UUID REFERENCES preventivi(id) ON DELETE SET NULL;

-- 2. Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_tasks_preventivo ON tasks(preventivo_id);

-- 3. Commento per documentazione
COMMENT ON COLUMN tasks.preventivo_id IS 'Collegamento al preventivo da cui è stata generata questa lavorazione';

-- Messaggio finale
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '✅ Campo preventivo_id aggiunto a tasks';
    RAISE NOTICE '📋 Ora puoi creare lavorazioni da preventivi accettati';
    RAISE NOTICE '';
END $$;

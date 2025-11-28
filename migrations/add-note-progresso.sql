-- =====================================================
-- Migration: Aggiungi campo note_progresso alla tabella tasks
-- Data: 28 novembre 2025
-- =====================================================

-- Aggiungi la colonna note_progresso
ALTER TABLE tasks 
ADD COLUMN note_progresso TEXT;

-- Aggiungi commento descrittivo
COMMENT ON COLUMN tasks.note_progresso IS 'Note di progresso inserite dal dipendente durante l''aggiornamento della lavorazione';

-- Aggiungi indice per ricerche veloci sulle note (optional ma utile)
CREATE INDEX idx_tasks_note_progresso ON tasks USING gin(to_tsvector('italian', note_progresso));

-- Log della migrazione
DO $$
BEGIN
    RAISE NOTICE 'Campo note_progresso aggiunto con successo alla tabella tasks';
END $$;

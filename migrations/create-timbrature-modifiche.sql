-- Migration: Crea tabella per lo storico modifiche timbrature
-- Descrizione: Sistema di tracking per tutte le modifiche effettuate sulle timbrature
-- Autore: AST Panel Admin System
-- Data: 2024

-- Tabella storico modifiche
CREATE TABLE IF NOT EXISTS timbrature_modifiche (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    timbratura_id UUID NOT NULL REFERENCES timbrature(id) ON DELETE CASCADE,
    campo_modificato VARCHAR(50) NOT NULL, -- es: 'ora_ingresso', 'ora_uscita', 'pausa_inizio', ecc.
    valore_vecchio TEXT, -- Valore prima della modifica (NULL se non esisteva)
    valore_nuovo TEXT, -- Valore dopo la modifica (NULL se eliminato)
    motivo TEXT NOT NULL, -- Motivo obbligatorio della modifica
    modificato_da UUID NOT NULL REFERENCES users(id), -- Admin che ha effettuato la modifica
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indici per performance
CREATE INDEX idx_timbrature_modifiche_timbratura ON timbrature_modifiche(timbratura_id);
CREATE INDEX idx_timbrature_modifiche_modificato_da ON timbrature_modifiche(modificato_da);
CREATE INDEX idx_timbrature_modifiche_created_at ON timbrature_modifiche(created_at DESC);

-- Commenti tabella
COMMENT ON TABLE timbrature_modifiche IS 'Storico completo di tutte le modifiche effettuate sulle timbrature';
COMMENT ON COLUMN timbrature_modifiche.campo_modificato IS 'Nome del campo modificato (es: ora_ingresso, pausa_fine)';
COMMENT ON COLUMN timbrature_modifiche.valore_vecchio IS 'Valore originale prima della modifica';
COMMENT ON COLUMN timbrature_modifiche.valore_nuovo IS 'Nuovo valore dopo la modifica';
COMMENT ON COLUMN timbrature_modifiche.motivo IS 'Motivazione obbligatoria della modifica inserita dall''admin';
COMMENT ON COLUMN timbrature_modifiche.modificato_da IS 'ID dell''utente admin che ha effettuato la modifica';

-- RLS (Row Level Security)
ALTER TABLE timbrature_modifiche ENABLE ROW LEVEL SECURITY;

-- Policy: Admin possono vedere tutte le modifiche
CREATE POLICY "Admin possono vedere tutte le modifiche" 
ON timbrature_modifiche FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Policy: Solo admin possono inserire modifiche
CREATE POLICY "Solo admin possono inserire modifiche" 
ON timbrature_modifiche FOR INSERT 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.ruolo IN ('Titolare', 'Amministratore', 'Tecnico', 'Segreteria')
    )
);

-- Dipendenti possono vedere solo le modifiche alle proprie timbrature
CREATE POLICY "Dipendenti vedono modifiche proprie timbrature" 
ON timbrature_modifiche FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM timbrature 
        WHERE timbrature.id = timbrature_modifiche.timbratura_id 
        AND timbrature.user_id = auth.uid()
    )
);

-- Function helper per ottenere storico modifiche di una timbratura
CREATE OR REPLACE FUNCTION get_timbratura_modifiche(timbratura_uuid UUID)
RETURNS TABLE (
    id UUID,
    campo_modificato VARCHAR,
    valore_vecchio TEXT,
    valore_nuovo TEXT,
    motivo TEXT,
    modificato_da_nome TEXT,
    modificato_da_cognome TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.id,
        tm.campo_modificato,
        tm.valore_vecchio,
        tm.valore_nuovo,
        tm.motivo,
        u.nome AS modificato_da_nome,
        u.cognome AS modificato_da_cognome,
        tm.created_at
    FROM timbrature_modifiche tm
    JOIN users u ON u.id = tm.modificato_da
    WHERE tm.timbratura_id = timbratura_uuid
    ORDER BY tm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT, INSERT ON timbrature_modifiche TO authenticated;
GRANT EXECUTE ON FUNCTION get_timbratura_modifiche(UUID) TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Tabella timbrature_modifiche creata con successo!';
    RAISE NOTICE '📋 Features: Tracking modifiche, RLS policies, Helper functions';
    RAISE NOTICE '🔐 Policies: Admin full access, Dipendenti read-only proprie modifiche';
END $$;

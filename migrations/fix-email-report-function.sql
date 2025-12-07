-- =====================================================
-- FIX: Function get_email_report_data
-- Problema: structure of query does not match function result type
-- Soluzione: DROP e ricreazione con struttura corretta
-- =====================================================

-- Step 1: Drop vecchia function (se esiste)
DROP FUNCTION IF EXISTS get_email_report_data(INTEGER, INTEGER);

-- Step 2: Ricrea con struttura corretta
CREATE OR REPLACE FUNCTION get_email_report_data(
    p_anno INTEGER,
    p_mese INTEGER
)
RETURNS TABLE (
    dipendente_nome TEXT,
    dipendente_cognome TEXT,
    dipendente_ruolo VARCHAR(50),
    costo_orario DECIMAL(10,2),
    totale_ore DECIMAL(10,2),
    totale_costo DECIMAL(10,2),
    giorni_lavorati INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.nome::TEXT,
        u.cognome::TEXT,
        u.ruolo::VARCHAR(50),
        COALESCE(u.costo_orario, 0)::DECIMAL(10,2),
        COALESCE(SUM(t.ore_lavorate), 0)::DECIMAL(10,2) AS totale_ore,
        COALESCE(SUM(t.ore_lavorate * COALESCE(u.costo_orario, 0)), 0)::DECIMAL(10,2) AS totale_costo,
        COUNT(DISTINCT t.data)::INTEGER AS giorni_lavorati
    FROM users u
    LEFT JOIN timbrature t ON t.user_id = u.id
        AND EXTRACT(YEAR FROM t.data) = p_anno
        AND EXTRACT(MONTH FROM t.data) = p_mese
        AND t.stato = 'approved'
    WHERE u.ruolo NOT IN ('Titolare', 'Amministratore') -- Escludi admin dal report
    GROUP BY u.id, u.nome, u.cognome, u.ruolo, u.costo_orario
    HAVING COALESCE(SUM(t.ore_lavorate), 0) > 0 -- Solo dipendenti con ore lavorate
    ORDER BY u.cognome, u.nome;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION get_email_report_data(INTEGER, INTEGER) TO authenticated;

-- Step 4: Test function
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO test_count 
    FROM get_email_report_data(2025, 12);
    
    RAISE NOTICE '✅ Function get_email_report_data ricreata con successo!';
    RAISE NOTICE '📊 Test dicembre 2025: % dipendenti con ore registrate', test_count;
END $$;

-- Success message
COMMENT ON FUNCTION get_email_report_data(INTEGER, INTEGER) IS 
'Restituisce dati report mensile dipendenti per PDF commercialista - FIXED 2025-12-07';

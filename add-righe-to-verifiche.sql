-- =====================================================
-- Aggiunge campi mancanti alla tabella verifiche:
-- - indirizzo (es. Pza Valperga 2, Caluso)
-- - quadro_descrizione (es. 1° piano + 2° piano + 3° piano)
-- - righe JSONB: array di {ubicazione, marca, n_poli, codice, esito}
-- =====================================================

ALTER TABLE verifiche
    ADD COLUMN IF NOT EXISTS indirizzo           text,
    ADD COLUMN IF NOT EXISTS quadro_descrizione  text,
    ADD COLUMN IF NOT EXISTS righe               jsonb DEFAULT '[]'::jsonb;

-- Migra i dati esistenti: sposta ubicazione/marca_n_poli/codice/esito dentro righe
UPDATE verifiche
SET righe = jsonb_build_array(
    jsonb_build_object(
        'ubicazione', COALESCE(ubicazione, ''),
        'marca',      COALESCE(marca_n_poli, ''),
        'n_poli',     '',
        'codice',     COALESCE(codice, ''),
        'esito',      CASE WHEN esito = 'conforme' THEN 'OK'
                           WHEN esito = 'non_conforme' THEN 'NON OK'
                           ELSE COALESCE(esito, 'OK') END
    )
)
WHERE (ubicazione IS NOT NULL OR marca_n_poli IS NOT NULL OR codice IS NOT NULL)
  AND (righe IS NULL OR righe = '[]'::jsonb);

SELECT 'Migrazione verifiche completata' AS status;

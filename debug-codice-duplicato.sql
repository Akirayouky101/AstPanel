-- Cerca il prodotto con codice HAC-HDW2501TMQ-A-S2 in tutti gli stati
-- (inclusi inattivi, eliminati, con spazi nascosti)

SELECT 
    id,
    codice,
    nome,
    descrizione,
    stato,
    categoria,
    created_at,
    LENGTH(codice) AS lunghezza_codice,
    TRIM(codice) AS codice_trim
FROM components
WHERE 
    UPPER(TRIM(codice)) = UPPER(TRIM('HAC-HDW2501TMQ-A-S2'))
    OR UPPER(codice) LIKE '%HAC-HDW2501TMQ%';

-- Se vuoi anche riattivarlo/modificarlo, usa questo UPDATE dopo aver trovato l'id:
-- UPDATE components SET stato = 'attivo' WHERE id = '<id-trovato>';
-- oppure per eliminarlo definitivamente:
-- DELETE FROM components WHERE id = '<id-trovato>';

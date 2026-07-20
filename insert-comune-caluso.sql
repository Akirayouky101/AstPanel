-- 1. Elimina entrambi i duplicati
DELETE FROM clients
WHERE ragione_sociale ILIKE '%Caluso%'
  AND tipo_cliente = 'comune';

-- 2. Inserisce Comune di Caluso con tutti i dati ufficiali
INSERT INTO clients (
    tipo_cliente,
    ragione_sociale,
    indirizzo,
    citta,
    cap,
    provincia,
    telefono,
    email,
    pec,
    partita_iva,
    codice_fiscale,
    sede_legale_indirizzo,
    sede_legale_citta,
    sede_legale_cap,
    sede_legale_provincia
) VALUES (
    'comune',
    'Comune di Caluso',
    'Piazza Valperga 2',
    'Caluso',
    '10014',
    'TO',
    '011 98 94 911',
    'protocollo@comune.caluso.to.it',
    'protocollo@pec.comune.caluso.to.it',
    '01109760015',
    '84002950016',
    'Piazza Valperga 2',
    'Caluso',
    '10014',
    'TO'
);

-- 3. Verifica
SELECT id, ragione_sociale, tipo_cliente, telefono, email, pec, partita_iva, codice_fiscale
FROM clients
WHERE ragione_sociale ILIKE '%Caluso%';


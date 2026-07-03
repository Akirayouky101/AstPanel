-- ============================================================
-- INSERIMENTO FORNITORE: Datacol S.r.l.
-- Fonte dati: www.datacol-group.com/contatti/
-- ============================================================
-- Esegui nel Supabase SQL Editor
-- ============================================================

INSERT INTO fornitori (
    ragione_sociale,
    partita_iva,
    codice_fiscale,
    email,
    telefono,
    indirizzo,
    citta,
    cap,
    provincia,
    nazione,
    categoria,
    attivo,
    logo_url
)
VALUES (
    'Datacol S.r.l.',
    '01964750234',
    '01964750234',
    'info@datacol.com',
    '+39 045 617 3888',
    'Località Ritonda, 100 – ZAI',
    'San Bonifacio',
    '37047',
    'VR',
    'Italia',
    'Viteria, Minuteria & Fissaggio',
    true,
    'https://www.datacol-group.com/wp-content/uploads/2023/07/Datacol_logo_RGB_nero_grigio_scuro_1x.png'
)
ON CONFLICT DO NOTHING;

-- Verifica inserimento
SELECT id, ragione_sociale, partita_iva, email, telefono, citta, logo_url, attivo, created_at
FROM fornitori
WHERE ragione_sociale ILIKE '%datacol%';

-- ============================================================
-- INSERT Fornitore: FIME Srl
-- Dati raccolti da https://www.fimesrl.it/
-- ESEGUIRE nel Supabase SQL Editor
-- ============================================================

INSERT INTO fornitori (
    ragione_sociale,
    categoria,
    partita_iva,
    email,
    telefono,
    indirizzo,
    citta,
    cap,
    provincia,
    logo_url,
    attivo,
    giorni_consegna,
    created_by
)
VALUES (
    'FIME Srl',
    'Prodotti e sistemi di fissaggio',
    '00799140231',
    'info@fimesrl.it',
    '045 6134211',
    'Largo Leonardo da Vinci, 8',
    'Belfiore',
    '37050',
    'VR',
    'https://www.fimesrl.it/media/logo/stores/1/logo_FIME_con_bordo.png',
    true,
    2,
    '00000000-0000-0000-0000-000000000001'
)
ON CONFLICT DO NOTHING;

-- Verifica
SELECT id, ragione_sociale, email, telefono, citta, provincia, logo_url
FROM fornitori
WHERE ragione_sociale = 'FIME Srl';

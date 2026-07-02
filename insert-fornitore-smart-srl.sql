-- =====================================================
-- INSERT FORNITORE: Smart Srl
-- Fonte: https://www.smartforyou.it
-- =====================================================

INSERT INTO fornitori (
    ragione_sociale,
    codice_fornitore,
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
    logo_url,
    note,
    attivo
)
VALUES (
    'Smart Srl',
    'SMART-SRL',
    '02412350023',
    '02412350023',
    'info@smartforyou.it',
    '+39 015980079',
    'Via Quintino Sella 96',
    'Valdengo',
    '13855',
    'BI',
    'Italia',
    'Sicurezza',
    'https://www.smartforyou.it/web/image/res.company/1/logo',
    'Partner per la sicurezza (TVCC, Antifurti, Automazioni, Videocitofonia, Controllo Accessi, Networking, Antincendio). REA: BI-188842. Sito: www.smartforyou.it',
    true
)
ON CONFLICT (codice_fornitore) DO NOTHING;

-- =====================================================
-- INSERT FORNITORE: Integra Group Srl
-- Fonte: https://www.integragroupsrl.com
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
    'Integra Group Srl',
    'INTEGRA-GROUP',
    '02676440965',
    '02676440965',
    'info@integragroupsrl.com',
    '0225390001',
    'Viale Spagna, 86',
    'Cologno Monzese',
    '20093',
    'MI',
    'Italia',
    'Sicurezza',
    'https://www.integragroupsrl.com/wp-content/uploads/2022/09/cropped-cropped-logosito.png',
    'Automazione cancelli e sicurezza. Sede Milano: Viale Spagna 86, tel. 0225390001. Sede Lodi: Strada Provinciale 115, 26855 Lodi Vecchio, tel. 0371421351 (infolodi@integragroupsrl.com). Sede Torino: Via G. Reiss Romoli 112/10/a, 10148, tel. 0117806802 (infotorino@integragroupsrl.com). Sito: www.integragroupsrl.com',
    true
)
ON CONFLICT (codice_fornitore) DO NOTHING;

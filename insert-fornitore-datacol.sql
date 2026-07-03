-- ============================================================
-- INSERIMENTO FORNITORE: Datacol
-- ============================================================
-- Esegui nel Supabase SQL Editor
-- Dopo l'inserimento, completa email/telefono/referente dalla
-- pagina Admin → Gestione Fornitori → Modifica
-- ============================================================

INSERT INTO fornitori (
    ragione_sociale,
    categoria,
    nazione,
    attivo,
    logo_url
)
VALUES (
    'Datacol',
    'Cavi & Connettori',
    'Italia',
    true,
    'https://logo.clearbit.com/datacol.it'
)
ON CONFLICT DO NOTHING;

-- Verifica inserimento
SELECT id, ragione_sociale, categoria, logo_url, attivo, created_at
FROM fornitori
WHERE ragione_sociale ILIKE '%datacol%';

-- =====================================================
-- SISTEMA MAGAZZINO OPERATORE
-- =====================================================
-- Permette ai dipendenti di registrare prelievi e
-- restituzioni parziali di materiale, con approvazione
-- da parte dell'admin prima che lo stock venga aggiornato.
-- =====================================================

-- =====================================================
-- 1. TABELLA MOVIMENTI OPERATORE (pending + history)
-- =====================================================
CREATE TABLE IF NOT EXISTS movimenti_operatore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Chi ha fatto il movimento
    operatore_id   UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    operatore_nome VARCHAR(255),  -- Cache nome al momento del movimento

    -- Prodotto
    prodotto_id    UUID NOT NULL REFERENCES components(id) ON DELETE RESTRICT,
    prodotto_nome  VARCHAR(255),  -- Cache nome prodotto
    prodotto_codice VARCHAR(100), -- Cache codice prodotto

    -- Tipo di movimento
    tipo           VARCHAR(20) NOT NULL CHECK (tipo IN ('prelievo', 'restituzione')),

    -- Quantità
    quantita_richiesta  DECIMAL(10,2) NOT NULL CHECK (quantita_richiesta > 0),
    quantita_effettiva  DECIMAL(10,2),  -- Compilato al rientro se diverso dal richiesto

    -- Stato approvazione
    stato VARCHAR(20) NOT NULL DEFAULT 'pending'
          CHECK (stato IN ('pending', 'approvato', 'rifiutato')),

    -- Note operatore
    note_operatore TEXT,

    -- Dati approvazione (compilati dall'admin)
    approvato_da   UUID REFERENCES users(id) ON DELETE SET NULL,
    approvato_at   TIMESTAMPTZ,
    note_admin     TEXT,

    -- Sessione: collega prelievo alla sua restituzione
    prelievo_ref_id UUID REFERENCES movimenti_operatore(id) ON DELETE SET NULL,

    -- Giacenza al momento del movimento (snapshot)
    giacenza_al_momento DECIMAL(10,2),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici performance
CREATE INDEX IF NOT EXISTS idx_mov_op_operatore  ON movimenti_operatore(operatore_id);
CREATE INDEX IF NOT EXISTS idx_mov_op_prodotto   ON movimenti_operatore(prodotto_id);
CREATE INDEX IF NOT EXISTS idx_mov_op_stato      ON movimenti_operatore(stato);
CREATE INDEX IF NOT EXISTS idx_mov_op_tipo       ON movimenti_operatore(tipo);
CREATE INDEX IF NOT EXISTS idx_mov_op_created    ON movimenti_operatore(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mov_op_prelievo   ON movimenti_operatore(prelievo_ref_id) WHERE prelievo_ref_id IS NOT NULL;

COMMENT ON TABLE movimenti_operatore IS 'Prelievi e restituzioni magazzino dei dipendenti, con flusso di approvazione admin';
COMMENT ON COLUMN movimenti_operatore.quantita_effettiva IS 'Quantità realmente restituita (può differire dal richiesto)';
COMMENT ON COLUMN movimenti_operatore.prelievo_ref_id IS 'Per le restituzioni: punta al prelievo originale';
COMMENT ON COLUMN movimenti_operatore.stato IS 'pending=attesa approvazione, approvato=stock aggiornato, rifiutato=ignorato';

-- =====================================================
-- 2. TRIGGER: updated_at automatico
-- =====================================================
CREATE OR REPLACE FUNCTION update_mov_op_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mov_op_updated_at ON movimenti_operatore;
CREATE TRIGGER trg_mov_op_updated_at
    BEFORE UPDATE ON movimenti_operatore
    FOR EACH ROW EXECUTE FUNCTION update_mov_op_updated_at();

-- =====================================================
-- 3. FUNZIONE: Approva movimento e aggiorna stock
-- =====================================================
-- Chiamata dall'admin. Aggiorna components.quantita_disponibile
-- e registra il movimento su movimenti_magazzino per storico unificato.
CREATE OR REPLACE FUNCTION approva_movimento_operatore(
    p_movimento_id UUID,
    p_admin_id     UUID,
    p_note_admin   TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_mov          movimenti_operatore%ROWTYPE;
    v_giacenza_pre DECIMAL(10,2);
    v_giacenza_post DECIMAL(10,2);
    v_delta        DECIMAL(10,2);
BEGIN
    -- 1. Leggi movimento
    SELECT * INTO v_mov
    FROM movimenti_operatore
    WHERE id = p_movimento_id AND stato = 'pending';

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'error', 'Movimento non trovato o già elaborato');
    END IF;

    -- 2. Calcola delta: prelievo = negativo, restituzione = positivo
    v_delta := CASE v_mov.tipo
        WHEN 'prelievo'      THEN -(COALESCE(v_mov.quantita_effettiva, v_mov.quantita_richiesta))
        WHEN 'restituzione'  THEN  (COALESCE(v_mov.quantita_effettiva, v_mov.quantita_richiesta))
    END;

    -- 3. Snapshot giacenza prima
    SELECT quantita_disponibile INTO v_giacenza_pre
    FROM components WHERE id = v_mov.prodotto_id;

    v_giacenza_post := v_giacenza_pre + v_delta;

    -- 4. Aggiorna stock componente
    UPDATE components
    SET quantita_disponibile = v_giacenza_post,
        updated_at = NOW()
    WHERE id = v_mov.prodotto_id;

    -- 5. Aggiorna stato movimento
    UPDATE movimenti_operatore
    SET stato          = 'approvato',
        approvato_da   = p_admin_id,
        approvato_at   = NOW(),
        note_admin     = p_note_admin,
        giacenza_al_momento = v_giacenza_pre,
        quantita_effettiva  = COALESCE(quantita_effettiva, quantita_richiesta)
    WHERE id = p_movimento_id;

    -- 6. Registra su movimenti_magazzino per cronologia unificata
    INSERT INTO movimenti_magazzino (
        prodotto_id,
        codice,
        descrizione,
        tipo_movimento,
        quantita,
        giacenza_prima,
        giacenza_dopo,
        causale,
        data_movimento,
        created_by,
        note
    )
    SELECT
        v_mov.prodotto_id,
        v_mov.prodotto_codice,
        v_mov.prodotto_nome,
        CASE v_mov.tipo WHEN 'prelievo' THEN 'scarico' ELSE 'carico' END,
        v_delta,
        v_giacenza_pre,
        v_giacenza_post,
        CASE v_mov.tipo
            WHEN 'prelievo'     THEN 'Prelievo operatore: ' || v_mov.operatore_nome
            WHEN 'restituzione' THEN 'Restituzione operatore: ' || v_mov.operatore_nome
        END,
        NOW(),
        p_admin_id,
        COALESCE(p_note_admin, v_mov.note_operatore)
    ;

    RETURN json_build_object(
        'ok', true,
        'giacenza_pre',  v_giacenza_pre,
        'giacenza_post', v_giacenza_post,
        'delta',         v_delta
    );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION approva_movimento_operatore(UUID, UUID, TEXT) TO authenticated;

-- =====================================================
-- 4. FUNZIONE: Rifiuta movimento
-- =====================================================
CREATE OR REPLACE FUNCTION rifiuta_movimento_operatore(
    p_movimento_id UUID,
    p_admin_id     UUID,
    p_note_admin   TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE movimenti_operatore
    SET stato        = 'rifiutato',
        approvato_da = p_admin_id,
        approvato_at = NOW(),
        note_admin   = p_note_admin
    WHERE id = p_movimento_id AND stato = 'pending';

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'error', 'Movimento non trovato o già elaborato');
    END IF;

    RETURN json_build_object('ok', true);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION rifiuta_movimento_operatore(UUID, UUID, TEXT) TO authenticated;

-- =====================================================
-- 5. RLS POLICIES
-- =====================================================
ALTER TABLE movimenti_operatore ENABLE ROW LEVEL SECURITY;

-- Dipendenti: possono INSERT (creare richieste) e SELECT dei propri movimenti
DROP POLICY IF EXISTS "operatore_insert_own" ON movimenti_operatore;
CREATE POLICY "operatore_insert_own" ON movimenti_operatore
    FOR INSERT WITH CHECK (true);  -- Qualsiasi authenticated può inserire

DROP POLICY IF EXISTS "operatore_select_own" ON movimenti_operatore;
CREATE POLICY "operatore_select_own" ON movimenti_operatore
    FOR SELECT USING (true);  -- Tutti i dipendenti vedono i movimenti (admin vede tutto)

-- Solo admin può UPDATE (approvare/rifiutare)
DROP POLICY IF EXISTS "admin_update_movimenti" ON movimenti_operatore;
CREATE POLICY "admin_update_movimenti" ON movimenti_operatore
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE auth_id = auth.uid()
            AND ruolo IN ('admin', 'superadmin')
        )
    );

-- =====================================================
-- 6. VISTA: Movimenti pending con dettagli
-- =====================================================
CREATE OR REPLACE VIEW v_movimenti_operatore_pending AS
SELECT
    mo.*,
    c.nome        AS prodotto_nome_live,
    c.codice      AS prodotto_codice_live,
    c.quantita_disponibile AS giacenza_attuale,
    c.unita_misura,
    u_op.nome     AS op_nome,
    u_op.cognome  AS op_cognome,
    u_op.email    AS op_email,
    u_adm.nome    AS admin_nome,
    u_adm.cognome AS admin_cognome
FROM movimenti_operatore mo
JOIN components c  ON c.id  = mo.prodotto_id
JOIN users u_op    ON u_op.id = mo.operatore_id
LEFT JOIN users u_adm ON u_adm.id = mo.approvato_da
ORDER BY mo.created_at DESC;

-- =====================================================
-- 7. VISTA: Cronologia completa movimenti operatore
-- =====================================================
CREATE OR REPLACE VIEW v_cronologia_movimenti_operatore AS
SELECT
    mo.id,
    mo.created_at,
    mo.tipo,
    mo.stato,
    mo.quantita_richiesta,
    mo.quantita_effettiva,
    mo.note_operatore,
    mo.note_admin,
    mo.approvato_at,
    mo.giacenza_al_momento,
    -- Prodotto
    c.nome            AS prodotto_nome,
    c.codice          AS prodotto_codice,
    c.unita_misura,
    -- Operatore
    CONCAT(u_op.nome, ' ', u_op.cognome) AS operatore_nome_completo,
    u_op.email        AS operatore_email,
    -- Admin
    CONCAT(u_adm.nome, ' ', u_adm.cognome) AS approvato_da_nome,
    -- Prelievo collegato (per restituzioni)
    ref.created_at    AS prelievo_originale_at,
    ref.quantita_richiesta AS prelievo_originale_qty
FROM movimenti_operatore mo
JOIN components c   ON c.id   = mo.prodotto_id
JOIN users u_op     ON u_op.id = mo.operatore_id
LEFT JOIN users u_adm ON u_adm.id = mo.approvato_da
LEFT JOIN movimenti_operatore ref ON ref.id = mo.prelievo_ref_id
ORDER BY mo.created_at DESC;

SELECT '✅ Sistema movimenti operatore creato con successo' AS status;

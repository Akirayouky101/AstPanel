-- ============================================================
-- CONTABILITA: scadenzario uscite/entrate per azienda e mese
-- Replica il foglio "Contabilità ZG AST" (un blocco per azienda)
-- con stato pagato/incassato, voci ricorrenti e saldo banca.
-- ============================================================

-- 1. MOVIMENTI (uscite = creditori, entrate = debitori)
CREATE TABLE IF NOT EXISTS public.contabilita_movimenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    azienda_id UUID NOT NULL REFERENCES public.aziende(id) ON DELETE RESTRICT,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('uscita', 'entrata')),
    controparte VARCHAR(200) NOT NULL,                  -- creditore / debitore
    fornitore_id UUID REFERENCES public.fornitori(id) ON DELETE SET NULL,
    cliente_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    descrizione VARCHAR(500),
    categoria VARCHAR(40) NOT NULL DEFAULT 'altro'
        CHECK (categoria IN ('stipendi', 'tasse', 'contributi', 'finanziamento', 'fornitore', 'utenze', 'carburante', 'multe', 'fattura_cliente', 'altro')),
    importo NUMERIC(12,2) NOT NULL CHECK (importo >= 0),
    data_riferimento DATE NOT NULL,                     -- scadenza (uscite) o emissione (entrate)
    mese_competenza DATE NOT NULL,                      -- primo giorno del mese del foglio
    stato VARCHAR(12) NOT NULL DEFAULT 'previsto' CHECK (stato IN ('previsto', 'pagato', 'annullato')),
    data_pagamento DATE,                                -- data effettiva pagamento / incasso
    importo_pagato NUMERIC(12,2),                       -- se diverso dall'importo previsto
    metodo VARCHAR(30),                                 -- bonifico, riba, f24, contanti, carta, sdd
    riferimento VARCHAR(100),                           -- numero fattura / documento
    note TEXT,
    ricorrente_id UUID,
    preventivo_id UUID,
    ordine_fornitore_id UUID,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. VOCI RICORRENTI (stipendi, F24, rate banca, canoni...)
CREATE TABLE IF NOT EXISTS public.contabilita_ricorrenti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    azienda_id UUID NOT NULL REFERENCES public.aziende(id) ON DELETE CASCADE,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('uscita', 'entrata')),
    controparte VARCHAR(200) NOT NULL,
    fornitore_id UUID REFERENCES public.fornitori(id) ON DELETE SET NULL,
    cliente_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    descrizione VARCHAR(500),
    categoria VARCHAR(40) NOT NULL DEFAULT 'altro',
    importo NUMERIC(12,2) NOT NULL CHECK (importo >= 0),
    giorno INTEGER NOT NULL DEFAULT 31 CHECK (giorno BETWEEN 1 AND 31), -- 31 = ultimo giorno del mese
    metodo VARCHAR(30),
    data_inizio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fine DATE,
    attivo BOOLEAN NOT NULL DEFAULT TRUE,
    note TEXT,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.contabilita_movimenti
    DROP CONSTRAINT IF EXISTS contabilita_movimenti_ricorrente_fk,
    ADD CONSTRAINT contabilita_movimenti_ricorrente_fk
        FOREIGN KEY (ricorrente_id) REFERENCES public.contabilita_ricorrenti(id) ON DELETE SET NULL;

-- Una sola generazione per voce ricorrente e mese
CREATE UNIQUE INDEX IF NOT EXISTS uq_contabilita_movimenti_ricorrente_mese
    ON public.contabilita_movimenti(ricorrente_id, mese_competenza) WHERE ricorrente_id IS NOT NULL;

-- 3. SALDI MENSILI (saldo banca inserito a mano, come nel foglio)
CREATE TABLE IF NOT EXISTS public.contabilita_saldi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    azienda_id UUID NOT NULL REFERENCES public.aziende(id) ON DELETE CASCADE,
    mese DATE NOT NULL,
    saldo_banca NUMERIC(12,2),
    note TEXT,
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (azienda_id, mese)
);

CREATE INDEX IF NOT EXISTS idx_contabilita_movimenti_azienda_mese ON public.contabilita_movimenti(azienda_id, mese_competenza);
CREATE INDEX IF NOT EXISTS idx_contabilita_movimenti_stato ON public.contabilita_movimenti(stato);
CREATE INDEX IF NOT EXISTS idx_contabilita_movimenti_data ON public.contabilita_movimenti(data_riferimento);
CREATE INDEX IF NOT EXISTS idx_contabilita_movimenti_fornitore ON public.contabilita_movimenti(fornitore_id);
CREATE INDEX IF NOT EXISTS idx_contabilita_movimenti_cliente ON public.contabilita_movimenti(cliente_id);
CREATE INDEX IF NOT EXISTS idx_contabilita_ricorrenti_azienda ON public.contabilita_ricorrenti(azienda_id) WHERE attivo;

-- 4. TRIGGER: mese_competenza coerente, stato/data_pagamento coerenti, updated_at
CREATE OR REPLACE FUNCTION public.contabilita_movimenti_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.mese_competenza IS NULL THEN
        NEW.mese_competenza := DATE_TRUNC('month', NEW.data_riferimento)::DATE;
    ELSE
        NEW.mese_competenza := DATE_TRUNC('month', NEW.mese_competenza)::DATE;
    END IF;
    IF NEW.stato = 'pagato' AND NEW.data_pagamento IS NULL THEN
        NEW.data_pagamento := CURRENT_DATE;
    END IF;
    IF NEW.stato <> 'pagato' THEN
        NEW.data_pagamento := NULL;
        NEW.importo_pagato := NULL;
    END IF;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_contabilita_movimenti_before_write ON public.contabilita_movimenti;
CREATE TRIGGER trg_contabilita_movimenti_before_write
    BEFORE INSERT OR UPDATE ON public.contabilita_movimenti
    FOR EACH ROW EXECUTE FUNCTION public.contabilita_movimenti_before_write();

CREATE OR REPLACE FUNCTION public.touch_contabilita_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_contabilita_ricorrenti_updated_at ON public.contabilita_ricorrenti;
CREATE TRIGGER trg_contabilita_ricorrenti_updated_at
    BEFORE UPDATE ON public.contabilita_ricorrenti
    FOR EACH ROW EXECUTE FUNCTION public.touch_contabilita_updated_at();

DROP TRIGGER IF EXISTS trg_contabilita_saldi_updated_at ON public.contabilita_saldi;
CREATE TRIGGER trg_contabilita_saldi_updated_at
    BEFORE UPDATE ON public.contabilita_saldi
    FOR EACH ROW EXECUTE FUNCTION public.touch_contabilita_updated_at();

-- 5. RPC: genera i movimenti del mese dalle voci ricorrenti attive (idempotente)
CREATE OR REPLACE FUNCTION public.genera_movimenti_ricorrenti(p_azienda_id UUID, p_mese DATE)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_mese DATE := DATE_TRUNC('month', p_mese)::DATE;
    v_ultimo DATE := (v_mese + INTERVAL '1 month - 1 day')::DATE;
    v_inseriti INTEGER := 0;
BEGIN
    WITH inseriti AS (
        INSERT INTO public.contabilita_movimenti
            (azienda_id, tipo, controparte, fornitore_id, cliente_id, descrizione, categoria, importo,
             data_riferimento, mese_competenza, metodo, ricorrente_id, created_by)
        SELECT r.azienda_id, r.tipo, r.controparte, r.fornitore_id, r.cliente_id, r.descrizione, r.categoria, r.importo,
               LEAST(v_mese + (r.giorno - 1), v_ultimo),
               v_mese, r.metodo, r.id, auth.uid()
        FROM public.contabilita_ricorrenti r
        WHERE r.azienda_id = p_azienda_id
          AND r.attivo
          AND r.data_inizio <= v_ultimo
          AND (r.data_fine IS NULL OR r.data_fine >= v_mese)
          AND NOT EXISTS (
              SELECT 1 FROM public.contabilita_movimenti m
              WHERE m.ricorrente_id = r.id AND m.mese_competenza = v_mese
          )
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_inseriti FROM inseriti;
    RETURN v_inseriti;
END;
$$;

-- 6. RPC: riepilogo mensile per azienda (totali del foglio calcolati)
CREATE OR REPLACE FUNCTION public.contabilita_riepilogo_mese(p_azienda_id UUID, p_mese DATE)
RETURNS TABLE (
    totale_uscite NUMERIC, uscite_evase NUMERIC, uscite_da_pagare NUMERIC, uscite_scadute NUMERIC,
    previsione_entrate NUMERIC, effettivi_entrati NUMERIC, entrate_da_incassare NUMERIC, entrate_in_ritardo NUMERIC,
    prev_utile NUMERIC, saldo_banca NUMERIC
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
    WITH m AS (
        SELECT * FROM public.contabilita_movimenti
        WHERE azienda_id = p_azienda_id
          AND stato <> 'annullato'
          AND (mese_competenza = DATE_TRUNC('month', p_mese)::DATE
               OR (mese_competenza < DATE_TRUNC('month', p_mese)::DATE AND stato = 'previsto'))
    ),
    u AS (
        SELECT COALESCE(SUM(importo), 0) AS tot,
               COALESCE(SUM(CASE WHEN stato = 'pagato' THEN COALESCE(importo_pagato, importo) END), 0) AS evase,
               COALESCE(SUM(CASE WHEN stato = 'previsto' THEN importo END), 0) AS aperte,
               COALESCE(SUM(CASE WHEN stato = 'previsto' AND data_riferimento < CURRENT_DATE THEN importo END), 0) AS scadute
        FROM m WHERE tipo = 'uscita'
    ),
    e AS (
        SELECT COALESCE(SUM(importo), 0) AS tot,
               COALESCE(SUM(CASE WHEN stato = 'pagato' THEN COALESCE(importo_pagato, importo) END), 0) AS incassate,
               COALESCE(SUM(CASE WHEN stato = 'previsto' THEN importo END), 0) AS aperte,
               COALESCE(SUM(CASE WHEN stato = 'previsto' AND data_riferimento < CURRENT_DATE - 30 THEN importo END), 0) AS in_ritardo
        FROM m WHERE tipo = 'entrata'
    )
    SELECT u.tot, u.evase, u.aperte, u.scadute, e.tot, e.incassate, e.aperte, e.in_ritardo, e.tot - u.tot,
           (SELECT s.saldo_banca FROM public.contabilita_saldi s
             WHERE s.azienda_id = p_azienda_id AND s.mese = DATE_TRUNC('month', p_mese)::DATE)
    FROM u, e;
$$;

-- 7. PERMESSI + RLS
GRANT SELECT, INSERT, UPDATE, DELETE ON public.contabilita_movimenti, public.contabilita_ricorrenti, public.contabilita_saldi TO authenticated;
GRANT EXECUTE ON FUNCTION public.genera_movimenti_ricorrenti(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.contabilita_riepilogo_mese(UUID, DATE) TO authenticated;

ALTER TABLE public.contabilita_movimenti ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contabilita_ricorrenti ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contabilita_saldi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS contabilita_movimenti_all ON public.contabilita_movimenti;
CREATE POLICY contabilita_movimenti_all ON public.contabilita_movimenti
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS contabilita_ricorrenti_all ON public.contabilita_ricorrenti;
CREATE POLICY contabilita_ricorrenti_all ON public.contabilita_ricorrenti
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS contabilita_saldi_all ON public.contabilita_saldi;
CREATE POLICY contabilita_saldi_all ON public.contabilita_saldi
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMENT ON TABLE public.contabilita_movimenti IS 'Scadenzario uscite (creditori) ed entrate (debitori) per azienda e mese di competenza';
COMMENT ON TABLE public.contabilita_ricorrenti IS 'Voci ricorrenti mensili che generano i movimenti (stipendi, F24, rate)';
COMMENT ON TABLE public.contabilita_saldi IS 'Saldo banca mensile inserito a mano per azienda';

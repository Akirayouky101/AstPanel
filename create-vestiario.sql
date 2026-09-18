-- Registro vestiario: capi assegnati ai dipendenti, con fornitore di provenienza.
CREATE TABLE IF NOT EXISTS public.vestiario_assegnazioni (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero VARCHAR(50) UNIQUE NOT NULL,
    fornitore_id UUID REFERENCES public.fornitori(id) ON DELETE SET NULL,
    fornitore_nome VARCHAR(200),
    dipendente_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
    dipendente_nome VARCHAR(200),
    data_assegnazione DATE NOT NULL DEFAULT CURRENT_DATE,
    stato VARCHAR(20) NOT NULL DEFAULT 'assegnato' CHECK (stato IN ('assegnato', 'restituito', 'danneggiato', 'eliminato')),
    note TEXT,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vestiario_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assegnazione_id UUID NOT NULL REFERENCES public.vestiario_assegnazioni(id) ON DELETE CASCADE,
    prodotto_id UUID REFERENCES public.components(id) ON DELETE SET NULL,
    codice VARCHAR(100),
    descrizione TEXT NOT NULL,
    taglia VARCHAR(30),
    quantita INTEGER NOT NULL DEFAULT 1 CHECK (quantita > 0),
    note VARCHAR(500),
    posizione INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vestiario_assegnazioni_dipendente ON public.vestiario_assegnazioni(dipendente_id);
CREATE INDEX IF NOT EXISTS idx_vestiario_assegnazioni_fornitore ON public.vestiario_assegnazioni(fornitore_id);
CREATE INDEX IF NOT EXISTS idx_vestiario_assegnazioni_data ON public.vestiario_assegnazioni(data_assegnazione DESC);
CREATE INDEX IF NOT EXISTS idx_vestiario_items_assegnazione ON public.vestiario_items(assegnazione_id);
CREATE INDEX IF NOT EXISTS idx_vestiario_items_codice ON public.vestiario_items(lower(codice));

CREATE OR REPLACE FUNCTION public.generate_vestiario_numero()
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    anno INTEGER := EXTRACT(YEAR FROM NOW());
    seq INTEGER;
BEGIN
    SELECT COALESCE(MAX(CAST(REGEXP_REPLACE(v.numero, '^VES-\d{4}-', '') AS INTEGER)), 0) + 1
    INTO seq
    FROM public.vestiario_assegnazioni v
    WHERE v.numero LIKE 'VES-' || anno || '-%';
    RETURN 'VES-' || anno || '-' || LPAD(seq::TEXT, 3, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.touch_vestiario_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_vestiario_assegnazioni_updated_at ON public.vestiario_assegnazioni;
CREATE TRIGGER trg_vestiario_assegnazioni_updated_at
    BEFORE UPDATE ON public.vestiario_assegnazioni
    FOR EACH ROW EXECUTE FUNCTION public.touch_vestiario_updated_at();

GRANT SELECT, INSERT, UPDATE, DELETE ON public.vestiario_assegnazioni, public.vestiario_items TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_vestiario_numero() TO authenticated;

ALTER TABLE public.vestiario_assegnazioni ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vestiario_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS vestiario_assegnazioni_all ON public.vestiario_assegnazioni;
CREATE POLICY vestiario_assegnazioni_all ON public.vestiario_assegnazioni
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS vestiario_items_all ON public.vestiario_items;
CREATE POLICY vestiario_items_all ON public.vestiario_items
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMENT ON TABLE public.vestiario_assegnazioni IS 'Assegnazioni di vestiario ai dipendenti con fornitore di provenienza';
COMMENT ON TABLE public.vestiario_items IS 'Capi assegnati: codice, descrizione, taglia e quantita';

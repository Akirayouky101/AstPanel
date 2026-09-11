-- Associa ogni prodotto a piu fornitori, con prezzo e codice specifici.
CREATE TABLE IF NOT EXISTS public.component_fornitori (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_id UUID NOT NULL REFERENCES public.components(id) ON DELETE CASCADE,
    fornitore_id UUID NOT NULL REFERENCES public.fornitori(id) ON DELETE CASCADE,
    prezzo_acquisto NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (prezzo_acquisto >= 0),
    codice_fornitore TEXT,
    principale BOOLEAN NOT NULL DEFAULT FALSE,
    attivo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (component_id, fornitore_id)
);

CREATE INDEX IF NOT EXISTS idx_component_fornitori_component
    ON public.component_fornitori(component_id);
CREATE INDEX IF NOT EXISTS idx_component_fornitori_fornitore
    ON public.component_fornitori(fornitore_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_component_fornitori_principale
    ON public.component_fornitori(component_id)
    WHERE principale AND attivo;

COMMENT ON TABLE public.component_fornitori IS
    'Fornitori associati ai prodotti, con prezzo e codice specifici per fornitore';

INSERT INTO public.component_fornitori (
    component_id, fornitore_id, prezzo_acquisto, principale
)
SELECT
    id,
    fornitore_id,
    COALESCE(prezzo_acquisto, prezzo_unitario, 0),
    TRUE
FROM public.components
WHERE fornitore_id IS NOT NULL
ON CONFLICT (component_id, fornitore_id) DO UPDATE
SET principale = TRUE,
    attivo = TRUE,
    prezzo_acquisto = EXCLUDED.prezzo_acquisto,
    updated_at = NOW();

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.component_fornitori TO authenticated;

ALTER TABLE public.component_fornitori ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "component_fornitori_select_authenticated" ON public.component_fornitori;
CREATE POLICY "component_fornitori_select_authenticated"
    ON public.component_fornitori FOR SELECT TO authenticated USING (TRUE);

DROP POLICY IF EXISTS "component_fornitori_insert_authenticated" ON public.component_fornitori;
CREATE POLICY "component_fornitori_insert_authenticated"
    ON public.component_fornitori FOR INSERT TO authenticated WITH CHECK (TRUE);

DROP POLICY IF EXISTS "component_fornitori_update_authenticated" ON public.component_fornitori;
CREATE POLICY "component_fornitori_update_authenticated"
    ON public.component_fornitori FOR UPDATE TO authenticated USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "component_fornitori_delete_authenticated" ON public.component_fornitori;
CREATE POLICY "component_fornitori_delete_authenticated"
    ON public.component_fornitori FOR DELETE TO authenticated USING (TRUE);

CREATE OR REPLACE FUNCTION public.set_component_fornitori(
    p_component_id UUID,
    p_fornitori JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_principale JSONB;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.components WHERE id = p_component_id) THEN
        RAISE EXCEPTION 'Prodotto non trovato';
    END IF;

    IF jsonb_typeof(COALESCE(p_fornitori, '[]'::JSONB)) <> 'array' THEN
        RAISE EXCEPTION 'La lista fornitori deve essere un array';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM jsonb_array_elements(COALESCE(p_fornitori, '[]'::JSONB)) item
        WHERE NULLIF(item->>'fornitore_id', '') IS NULL
           OR COALESCE((item->>'prezzo_acquisto')::NUMERIC, 0) < 0
    ) THEN
        RAISE EXCEPTION 'Fornitore o prezzo non valido';
    END IF;

    SELECT item INTO v_principale
    FROM jsonb_array_elements(COALESCE(p_fornitori, '[]'::JSONB)) item
    ORDER BY COALESCE((item->>'principale')::BOOLEAN, FALSE) DESC
    LIMIT 1;

    DELETE FROM public.component_fornitori WHERE component_id = p_component_id;

    INSERT INTO public.component_fornitori (
        component_id, fornitore_id, prezzo_acquisto, codice_fornitore, principale, attivo
    )
    SELECT
        p_component_id,
        (item->>'fornitore_id')::UUID,
        COALESCE((item->>'prezzo_acquisto')::NUMERIC, 0),
        NULLIF(trim(item->>'codice_fornitore'), ''),
        item = v_principale,
        TRUE
    FROM jsonb_array_elements(COALESCE(p_fornitori, '[]'::JSONB)) item;

    UPDATE public.components
    SET fornitore_id = (v_principale->>'fornitore_id')::UUID,
        fornitore_preferito_id = (v_principale->>'fornitore_id')::UUID,
        prezzo_acquisto = COALESCE((v_principale->>'prezzo_acquisto')::NUMERIC, 0),
        prezzo_unitario = COALESCE((v_principale->>'prezzo_acquisto')::NUMERIC, 0)
    WHERE id = p_component_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_component_fornitori(UUID, JSONB) TO authenticated;
// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const RESEND_API_KEY        = Deno.env.get('RESEND_API_KEY')!;
const FROM_EMAIL            = Deno.env.get('FROM_EMAIL') ?? 'ordini@zgimpianti.it';
const FROM_NAME             = 'ZG Impianti – Ordini';
const FROM_NAME_PREVENTIVO  = 'Richiesta Preventivo';

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, x-client-info, content-type',
};

const fmt = (d?: string | null) => {
  if (!d) return '—';
  const [y, m, day] = d.split('-');
  return `${day}/${m}/${y}`;
};

// ── Ordine Fornitore ──────────────────────────────────────────────────────────
function buildOrdineHtml(p: Record<string, unknown>): string {
  const { toName, fornitoreNome, numeroOrdine, oggetto, dataOrdine, dataConsegna, prodotti, note } = p as {
    toName?: string; fornitoreNome: string; numeroOrdine: string; oggetto: string;
    dataOrdine: string; dataConsegna?: string | null;
    prodotti: Array<{ codice?: string; descrizione: string; quantita: number; um?: string }>;
    note?: string | null;
  };

  const righe = (prodotti ?? []).map(r => `
    <tr style="border-bottom:1px solid #f3f4f6">
      <td style="padding:10px 12px;font-size:13px;color:#374151;font-family:monospace">${r.codice ?? '—'}</td>
      <td style="padding:10px 12px;font-size:13px;color:#111827;font-weight:600">${r.descrizione ?? '—'}</td>
      <td style="padding:10px 12px;font-size:13px;color:#374151;text-align:center">${r.quantita ?? 0} ${r.um ?? 'pz'}</td>
    </tr>`).join('');

  return `<!DOCTYPE html>
<html lang="it"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f9fafb;font-family:'Helvetica Neue',Arial,sans-serif">
<div style="max-width:680px;margin:32px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08)">
  <div style="background:linear-gradient(135deg,#ea580c,#f59e0b);padding:32px 40px">
    <div style="display:flex;align-items:center;gap:12px">
      <div style="font-size:36px">📦</div>
      <div>
        <h1 style="margin:0;font-size:22px;font-weight:800;color:#fff">Ordine Fornitore</h1>
        <p style="margin:4px 0 0;color:rgba(255,255,255,0.85);font-size:14px">${FROM_NAME}</p>
      </div>
    </div>
  </div>
  <div style="padding:32px 40px">
    <p style="margin:0 0 24px;font-size:15px;color:#374151">
      Gentile <strong>${toName ?? fornitoreNome}</strong>,<br><br>
      Le trasmettiamo il seguente ordine. La preghiamo di confermare la ricezione rispondendo a questa email.
    </p>
    <div style="background:#fff7ed;border:2px solid #fed7aa;border-radius:12px;padding:20px;margin-bottom:24px">
      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280;width:140px">Numero Ordine</td><td style="padding:6px 0;font-size:14px;font-weight:700;color:#ea580c">${numeroOrdine}</td></tr>
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Oggetto</td><td style="padding:6px 0;font-size:14px;font-weight:600;color:#111827">${oggetto}</td></tr>
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Data Ordine</td><td style="padding:6px 0;font-size:14px;color:#374151">${fmt(dataOrdine)}</td></tr>
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Consegna Prevista</td><td style="padding:6px 0;font-size:14px;color:#374151">${fmt(dataConsegna)}</td></tr>
      </table>
    </div>
    <h3 style="margin:0 0 12px;font-size:15px;font-weight:700;color:#111827">Prodotti Ordinati</h3>
    <div style="border-radius:10px;overflow:hidden;border:1px solid #e5e7eb">
      <table style="width:100%;border-collapse:collapse">
        <thead>
          <tr style="background:linear-gradient(135deg,#7c3aed,#6d28d9)">
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Codice</th>
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Descrizione</th>
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:center;text-transform:uppercase">Q.tà</th>
          </tr>
        </thead>
        <tbody>
          ${righe || '<tr><td colspan="3" style="padding:20px;text-align:center;color:#9ca3af;font-size:13px">Nessun prodotto</td></tr>'}
        </tbody>
      </table>
    </div>
    ${note ? '<div style="margin-top:24px;background:#f9fafb;border-left:4px solid #f59e0b;padding:14px 18px;border-radius:0 10px 10px 0"><p style="margin:0 0 4px;font-size:12px;font-weight:700;color:#92400e;text-transform:uppercase">Note</p><p style="margin:0;font-size:14px;color:#374151">' + note + '</p></div>' : ''}
  </div>
  <div style="background:#f3f4f6;padding:20px 40px;text-align:center">
    <p style="margin:0;font-size:12px;color:#9ca3af">Questo messaggio è stato generato automaticamente da <strong>ZG Impianti Panel</strong>.<br>Per qualsiasi chiarimento risponda a questa email oppure contatti il nostro ufficio acquisti.</p>
  </div>
</div>
</body></html>`;
}

// ── Richiesta Preventivo ──────────────────────────────────────────────────────
function buildPreventivoHtml(p: Record<string, unknown>): string {
  const { toName, fornitoreNome, numeroRichiesta, oggetto, dataRichiesta, dataRispostaEntro, articoli, note } = p as {
    toName?: string; fornitoreNome: string; numeroRichiesta: string; oggetto: string;
    dataRichiesta: string; dataRispostaEntro?: string | null;
    articoli: Array<{ codice?: string; descrizione: string; quantita: number; um?: string }>;
    note?: string | null;
  };

  const righe = (articoli ?? []).map(r => `
    <tr style="border-bottom:1px solid #f0fdfa">
      <td style="padding:10px 12px;font-size:13px;color:#0f766e;font-family:monospace">${r.codice ?? '—'}</td>
      <td style="padding:10px 12px;font-size:13px;color:#111827;font-weight:600">${r.descrizione ?? '—'}</td>
      <td style="padding:10px 12px;font-size:13px;color:#374151;text-align:center">${r.quantita ?? 0} ${r.um ?? 'pz'}</td>
    </tr>`).join('');

  return `<!DOCTYPE html>
<html lang="it"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f9fafb;font-family:'Helvetica Neue',Arial,sans-serif">
<div style="max-width:680px;margin:32px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08)">
  <div style="background:linear-gradient(135deg,#0d9488,#0891b2);padding:32px 40px">
    <div style="display:flex;align-items:center;gap:12px">
      <div style="font-size:40px">📋</div>
      <div>
        <h1 style="margin:0;font-size:28px;font-weight:800;color:#fff">Richiesta di Preventivo</h1>
      </div>
    </div>
  </div>
  <div style="padding:32px 40px">
    <p style="margin:0 0 24px;font-size:15px;color:#374151">
      Gentile <strong>${toName ?? fornitoreNome}</strong>,<br><br>
      Vi chiediamo cortesemente di inviarci un preventivo per i seguenti articoli. La preghiamo di rispondere a questa email con prezzi e disponibilità.
    </p>
    <div style="background:#f0fdfa;border:2px solid #99f6e4;border-radius:12px;padding:20px;margin-bottom:24px">
      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280;width:160px">Numero Richiesta</td><td style="padding:6px 0;font-size:14px;font-weight:700;color:#0d9488">${numeroRichiesta}</td></tr>
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Oggetto</td><td style="padding:6px 0;font-size:14px;font-weight:600;color:#111827">${oggetto}</td></tr>
        <tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Data Richiesta</td><td style="padding:6px 0;font-size:14px;color:#374151">${fmt(dataRichiesta)}</td></tr>
        ${dataRispostaEntro ? `<tr><td style="padding:6px 0;font-size:13px;color:#6b7280">Risposta Entro</td><td style="padding:6px 0;font-size:14px;font-weight:700;color:#dc2626">${fmt(dataRispostaEntro)}</td></tr>` : ''}
      </table>
    </div>
    <h3 style="margin:0 0 12px;font-size:15px;font-weight:700;color:#111827">Articoli Richiesti</h3>
    <div style="border-radius:10px;overflow:hidden;border:1px solid #99f6e4">
      <table style="width:100%;border-collapse:collapse">
        <thead>
          <tr style="background:linear-gradient(135deg,#0d9488,#0891b2)">
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Codice</th>
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Descrizione</th>
            <th style="padding:10px 12px;font-size:12px;font-weight:700;color:#fff;text-align:center;text-transform:uppercase">Q.tà</th>
          </tr>
        </thead>
        <tbody>
          ${righe || '<tr><td colspan="3" style="padding:20px;text-align:center;color:#9ca3af;font-size:13px">Nessun articolo</td></tr>'}
        </tbody>
      </table>
    </div>
    ${note ? '<div style="margin-top:24px;background:#f9fafb;border-left:4px solid #0d9488;padding:14px 18px;border-radius:0 10px 10px 0"><p style="margin:0 0 4px;font-size:12px;font-weight:700;color:#0f766e;text-transform:uppercase">Note</p><p style="margin:0;font-size:14px;color:#374151">' + note + '</p></div>' : ''}
  </div>
  <div style="background:#f3f4f6;padding:20px 40px;text-align:center">
    <p style="margin:0;font-size:12px;color:#9ca3af">Questo messaggio è stato generato automaticamente da <strong>ZG Impianti Panel</strong>.<br>Per rispondere o per chiarimenti, risponda a questa email.</p>
  </div>
</div>
</body></html>`;
}

// ── Richiesta Approvazione Ordine Interno ─────────────────────────────────────
function buildApprovazioneHtml(p: Record<string, unknown>): string {
  const { numero, oggetto, fornitore, totale, approvalUrl } = p as {
    numero: string; oggetto: string; fornitore?: string; totale?: string; approvalUrl: string;
  };
  const totaleStr = totale
    ? `€ ${parseFloat(totale).toLocaleString('it-IT', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    : '—';

  return `<!DOCTYPE html>
<html lang="it"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f5f3ff;font-family:'Helvetica Neue',Arial,sans-serif">
<div style="max-width:600px;margin:32px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.1)">
  <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);padding:36px 40px">
    <div style="display:flex;align-items:center;gap:14px">
      <div style="font-size:40px">⏳</div>
      <div>
        <h1 style="margin:0;font-size:22px;font-weight:800;color:#fff">Richiesta di Approvazione</h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.8);font-size:14px">ZG Impianti – Ordini Interni</p>
      </div>
    </div>
  </div>
  <div style="padding:36px 40px">
    <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6">
      È stato creato un nuovo ordine interno in attesa di approvazione.<br>
      Usa il pulsante qui sotto per visualizzare i dettagli e approvarlo o rifiutarlo.
    </p>
    <div style="background:#f5f3ff;border:2px solid #ddd6fe;border-radius:14px;padding:22px;margin-bottom:28px">
      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:8px 0;font-size:12px;color:#6b7280;width:130px;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Numero</td><td style="padding:8px 0;font-size:16px;font-weight:800;color:#7c3aed">${numero}</td></tr>
        <tr><td style="padding:8px 0;font-size:12px;color:#6b7280;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Oggetto</td><td style="padding:8px 0;font-size:15px;font-weight:600;color:#111827">${oggetto}</td></tr>
        ${fornitore ? `<tr><td style="padding:8px 0;font-size:12px;color:#6b7280;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Fornitore</td><td style="padding:8px 0;font-size:14px;color:#374151">${fornitore}</td></tr>` : ''}
        <tr><td style="padding:8px 0;font-size:12px;color:#6b7280;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Totale</td><td style="padding:8px 0;font-size:16px;font-weight:700;color:#059669">${totaleStr}</td></tr>
      </table>
    </div>
    <div style="text-align:center;margin-bottom:28px">
      <a href="${approvalUrl}" style="display:inline-block;padding:16px 40px;background:linear-gradient(135deg,#7c3aed,#6d28d9);color:#fff;font-size:15px;font-weight:700;text-decoration:none;border-radius:12px;box-shadow:0 4px 14px rgba(124,58,237,0.4)">
        📋&nbsp;&nbsp;Gestisci Approvazione →
      </a>
    </div>
    <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">
      Il link è valido per <strong>30 giorni</strong> e può essere usato una sola volta.<br>
      Se non sei la persona designata, ignora questa email.
    </p>
  </div>
  <div style="background:#f3f4f6;padding:18px 40px;text-align:center;border-top:1px solid #e5e7eb">
    <p style="margin:0;font-size:12px;color:#9ca3af">Generato automaticamente da <strong>ZG Impianti Panel</strong></p>
  </div>
</div>
</body></html>`;
}

// ── Richiesta Approvazione Preventivo Fornitore ───────────────────────────────
function buildApprovazionePreventivoHtml(p: Record<string, unknown>): string {
  const { approvatore, numero, oggetto, fornitore, articoli, approvalUrl } = p as {
    approvatore?: string; numero: string; oggetto: string; fornitore?: string;
    articoli?: Array<{ codice?: string; descrizione: string; quantita: number; um?: string }>;
    approvalUrl: string;
  };

  const righe = (articoli ?? []).slice(0, 10).map(r => `
    <tr style="border-bottom:1px solid #f0fdfa">
      <td style="padding:8px 12px;font-size:12px;color:#0f766e;font-family:monospace">${r.codice ?? '—'}</td>
      <td style="padding:8px 12px;font-size:13px;color:#111827;font-weight:600">${r.descrizione ?? '—'}</td>
      <td style="padding:8px 12px;font-size:13px;color:#374151;text-align:center">${r.quantita ?? 0} ${r.um ?? 'pz'}</td>
    </tr>`).join('');

  const extra = (articoli?.length ?? 0) > 10
    ? `<tr><td colspan="3" style="padding:8px 12px;font-size:12px;color:#9ca3af;font-style:italic;text-align:center">... e altri ${(articoli?.length ?? 0) - 10} articoli</td></tr>`
    : '';

  return `<!DOCTYPE html>
<html lang="it"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f0fdfa;font-family:'Helvetica Neue',Arial,sans-serif">
<div style="max-width:620px;margin:32px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.1)">
  <div style="background:linear-gradient(135deg,#0d9488,#0891b2);padding:36px 40px">
    <div style="display:flex;align-items:center;gap:14px">
      <div style="font-size:40px">📋</div>
      <div>
        <h1 style="margin:0;font-size:22px;font-weight:800;color:#fff">Approvazione Richiesta Preventivo</h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.8);font-size:14px">ZG Impianti – Richieste Fornitori</p>
      </div>
    </div>
  </div>
  <div style="padding:36px 40px">
    <p style="margin:0 0 24px;font-size:15px;color:#374151;line-height:1.6">
      ${approvatore ? `Ciao <strong>${approvatore}</strong>,<br><br>` : ''}
      È stata creata una nuova richiesta di preventivo in attesa di approvazione.
      Puoi approvare o rifiutare tramite il pannello qui sotto.<br>
      <span style="font-size:13px;color:#9ca3af;font-style:italic">Nota: anche se rifiutata, la richiesta può essere inviata al fornitore.</span>
    </p>
    <div style="background:#f0fdfa;border:2px solid #99f6e4;border-radius:14px;padding:22px;margin-bottom:24px">
      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:7px 0;font-size:12px;color:#6b7280;width:140px;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Numero</td><td style="padding:7px 0;font-size:16px;font-weight:800;color:#0d9488">${numero}</td></tr>
        <tr><td style="padding:7px 0;font-size:12px;color:#6b7280;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Oggetto</td><td style="padding:7px 0;font-size:15px;font-weight:600;color:#111827">${oggetto}</td></tr>
        ${fornitore ? `<tr><td style="padding:7px 0;font-size:12px;color:#6b7280;font-weight:700;text-transform:uppercase;letter-spacing:.5px">Fornitore</td><td style="padding:7px 0;font-size:14px;color:#374151">${fornitore}</td></tr>` : ''}
      </table>
    </div>
    ${articoli?.length ? `
    <h3 style="margin:0 0 10px;font-size:14px;font-weight:700;color:#374151">Articoli (${articoli.length})</h3>
    <div style="border-radius:10px;overflow:hidden;border:1px solid #99f6e4;margin-bottom:24px">
      <table style="width:100%;border-collapse:collapse">
        <thead><tr style="background:linear-gradient(135deg,#0d9488,#0891b2)">
          <th style="padding:9px 12px;font-size:11px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Codice</th>
          <th style="padding:9px 12px;font-size:11px;font-weight:700;color:#fff;text-align:left;text-transform:uppercase">Descrizione</th>
          <th style="padding:9px 12px;font-size:11px;font-weight:700;color:#fff;text-align:center;text-transform:uppercase">Q.tà</th>
        </tr></thead>
        <tbody>${righe}${extra}</tbody>
      </table>
    </div>` : ''}
    <div style="text-align:center;margin-bottom:24px">
      <a href="${approvalUrl}" style="display:inline-block;padding:16px 40px;background:linear-gradient(135deg,#0d9488,#0891b2);color:#fff;font-size:15px;font-weight:700;text-decoration:none;border-radius:12px;box-shadow:0 4px 14px rgba(13,148,136,0.4)">
        📋&nbsp;&nbsp;Apri Pannello Approvazione →
      </a>
    </div>
    <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">
      Il link è personale e può essere usato più volte.<br>
      Se non sei la persona designata, ignora questa email.
    </p>
  </div>
  <div style="background:#f3f4f6;padding:18px 40px;text-align:center;border-top:1px solid #e5e7eb">
    <p style="margin:0;font-size:12px;color:#9ca3af">Generato automaticamente da <strong>ZG Impianti Panel</strong></p>
  </div>
</div>
</body></html>`;
}

// ── Handler principale ────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS });
  }

  try {
    const payload = await req.json();
    const { to, tipo } = payload;

    if (!to) {
      return new Response(JSON.stringify({ error: 'Email destinatario mancante' }), {
        status: 400, headers: { ...CORS, 'Content-Type': 'application/json' }
      });
    }

    let html: string;
    let subject: string;
    let fromName: string;
    if (tipo === 'preventivo') {
      html     = buildPreventivoHtml(payload);
      subject  = `[${payload.numeroRichiesta}] Richiesta Preventivo – ZG Impianti`;
      fromName = FROM_NAME_PREVENTIVO;
    } else if (tipo === 'approvazione') {
      html     = buildApprovazioneHtml(payload);
      subject  = `⏳ Approvazione richiesta – Ordine ${payload.numero} – ZG Impianti`;
      fromName = FROM_NAME;
    } else if (tipo === 'approvazione_preventivo') {
      html     = buildApprovazionePreventivoHtml(payload);
      subject  = `⏳ Approvazione richiesta preventivo ${payload.numero} – ZG Impianti`;
      fromName = FROM_NAME;
    } else {
      html     = buildOrdineHtml(payload);
      subject  = `[${payload.numeroOrdine}] ${payload.oggetto} – ZG Impianti`;
      fromName = FROM_NAME;
    }

    // CC opzionale (usato per richieste preventivo con referente + ufficio)
    const cc: string | undefined = typeof payload.cc === 'string' && payload.cc ? payload.cc : undefined;

    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${fromName} <${FROM_EMAIL}>`,
        to:      [to],
        ...(cc ? { cc: [cc] } : {}),
        subject,
        html,
      }),
    });

    const data = await resendRes.json();

    if (!resendRes.ok) {
      console.error('Resend error:', data);
      return new Response(JSON.stringify({ error: data.message ?? 'Errore invio email' }), {
        status: 500, headers: { ...CORS, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ success: true, id: data.id }), {
      headers: { ...CORS, 'Content-Type': 'application/json' }
    });

  } catch (err) {
    console.error('Function error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...CORS, 'Content-Type': 'application/json' }
    });
  }
});

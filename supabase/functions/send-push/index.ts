/**
 * ZG Impianti – Supabase Edge Function: send-push
 *
 * Triggered da Database Webhook quando un task viene creato (INSERT)
 * o assegnato (UPDATE su assigned_user_id).
 *
 * DEPLOY:
 *   supabase functions deploy send-push
 *
 * VARIABILI DA IMPOSTARE in Supabase Dashboard → Project Settings → Edge Functions:
 *   VAPID_PUBLIC_KEY  = BCsyrTqzG2BhGSXfxefMSTttkYgrwlObrgP0UlXWijqhg59qdUIR4hmZOOzHB8PrsAYYKvejEliCvR4fvKgFz0E
 *   VAPID_PRIVATE_KEY = vqUt-BNYJ3hJVqJ3Nu5dnMX6jiTxFs3px34LTxkYTVc
 *   VAPID_SUBJECT     = mailto:admin@zgimpianti.it
 *
 * DATABASE WEBHOOK (da creare in Supabase Dashboard → Database → Webhooks):
 *   Name:   notify-on-task
 *   Table:  tasks
 *   Events: INSERT, UPDATE
 *   URL:    https://<project-ref>.supabase.co/functions/v1/send-push
 *   Headers: Authorization: Bearer <ANON_KEY>
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Web Push via esm.sh (no npm needed in Deno)
import webpush from 'https://esm.sh/web-push@3.6.7';

const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const VAPID_PUBLIC_KEY  = Deno.env.get('VAPID_PUBLIC_KEY')!;
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY')!;
const VAPID_SUBJECT     = Deno.env.get('VAPID_SUBJECT') || 'mailto:admin@zgimpianti.it';

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

serve(async (req: Request) => {
    try {
        const body = await req.json();

        // ── Caso 1: chiamata diretta per notifica approvazione ────────────────────
        // Body: { type: 'APPROVAL', numero, fornitore, azione, approvatore }
        if (body.type === 'APPROVAL') {
            const { numero, fornitore, azione, approvatore } = body;

            const azioneLabel: Record<string, string> = {
                approva:         '✅ Approvata',
                approva_modifica:'✅ Modifica approvata',
                rifiuta:         '❌ Rifiutata',
                prendi_visione:  '👁️ Presa visione',
            };
            const label = azioneLabel[azione] || azione;

            const payload = JSON.stringify({
                title: `${label} – ${numero}`,
                body:  `Fornitore: ${fornitore || '—'} · da ${approvatore || 'Approvatore'}`,
                tag:   `approvazione-${numero}`,
                requireInteraction: true,
                data:  { url: '/Admin/richiesta-preventivi-fornitori.html' },
            });

            // Invia a TUTTE le push subscription (tutti i dispositivi registrati degli admin)
            const { data: subs, error: subErr } = await supabase
                .from('push_subscriptions')
                .select('endpoint, key_p256dh, key_auth');

            if (subErr || !subs?.length) return new Response('No subscriptions', { status: 200 });

            let sent = 0;
            for (const sub of subs) {
                try {
                    await webpush.sendNotification(
                        { endpoint: sub.endpoint, keys: { p256dh: sub.key_p256dh, auth: sub.key_auth } },
                        payload
                    );
                    sent++;
                } catch (_) { /* subscription scaduta/invalida: ignora */ }
            }
            console.log(`✅ Push approvazione inviata a ${sent}/${subs.length} dispositivi`);
            return new Response(JSON.stringify({ ok: true, sent }), { status: 200 });
        }

        // ── Caso 2: Webhook Supabase per task (comportamento originale) ───────────
        const eventType: string  = body.type;
        const record: Record<string, unknown> = body.record;

        // Solo INSERT o UPDATE con assigned_user_id
        const userId = record?.assigned_user_id as string | null;
        if (!userId) return new Response('No assigned user', { status: 200 });

        // Per UPDATE: notifica solo se assigned_user_id è cambiato
        if (eventType === 'UPDATE') {
            const oldUserId = body.old_record?.assigned_user_id;
            if (oldUserId === userId) return new Response('No change', { status: 200 });
        }

        // Recupera la subscription del dipendente
        const { data: subs, error } = await supabase
            .from('push_subscriptions')
            .select('endpoint, key_p256dh, key_auth')
            .eq('dipendente_id', userId)
            .limit(1);

        if (error || !subs?.length) return new Response('No subscription', { status: 200 });

        const sub = subs[0];
        const pushSub = {
            endpoint: sub.endpoint,
            keys: { p256dh: sub.key_p256dh, auth: sub.key_auth }
        };

        const payload = JSON.stringify({
            title: eventType === 'INSERT' ? '📋 Nuova lavorazione!' : '📝 Lavorazione aggiornata',
            body:  (record.titolo as string) || 'Controlla la tua giornata',
            url:   '/giornaliero-dipendente.html',
            tag:   `task-${record.id}`,
            requireInteraction: eventType === 'INSERT'
        });

        await webpush.sendNotification(pushSub, payload);
        console.log(`✅ Push inviata a dipendente ${userId} (task: ${record.id})`);

        return new Response('OK', { status: 200 });

    } catch (err) {
        console.error('send-push error:', err);
        return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
    }
});

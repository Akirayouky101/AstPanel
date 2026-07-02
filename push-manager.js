/**
 * ZG Impianti - PWA Manager
 * Gestisce: Service Worker, Push Notifications, Badge API, Realtime in-app
 *
 * Uso: dopo aver caricato supabase-client.js, aggiungi:
 *   <script src="/push-manager.js"></script>
 * e chiama:
 *   window.ZGPwa.init(dipId)   // nelle pagine dipendente
 */

(function () {
    'use strict';

    // ── Chiave pubblica VAPID ───────────────────────────────────────────────
    const VAPID_PUBLIC_KEY =
        'BCsyrTqzG2BhGSXfxefMSTttkYgrwlObrgP0UlXWijqhg59qdUIR4hmZOOzHB8PrsAYYKvejEliCvR4fvKgFz0E';

    // ── Utility: base64url → Uint8Array (richiesta da PushManager.subscribe) ─
    function urlB64ToUint8(b64) {
        const pad = '='.repeat((4 - b64.length % 4) % 4);
        const b   = atob((b64 + pad).replace(/-/g, '+').replace(/_/g, '/'));
        return Uint8Array.from(b, c => c.charCodeAt(0));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 1 · SERVICE WORKER
    // ═══════════════════════════════════════════════════════════════════════
    async function registerSW() {
        if (!('serviceWorker' in navigator)) return null;
        try {
            const reg = await navigator.serviceWorker.register('/sw.js', { scope: '/' });

            // Aggiornamento silenzioso: attiva subito il nuovo SW
            reg.addEventListener('updatefound', () => {
                const worker = reg.installing;
                worker.addEventListener('statechange', () => {
                    if (worker.state === 'installed' && navigator.serviceWorker.controller) {
                        worker.postMessage({ type: 'SKIP_WAITING' });
                    }
                });
            });

            return reg;
        } catch (e) {
            console.warn('[ZGPwa] SW registration failed:', e);
            return null;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2 · BADGE API
    // ═══════════════════════════════════════════════════════════════════════
    async function setBadge(count) {
        // API nativa (Android TWA, Edge, Chrome desktop)
        if ('setAppBadge' in navigator) {
            try {
                count > 0 ? await navigator.setAppBadge(count) : await navigator.clearAppBadge();
            } catch (_) {}
        }
        // Aggiorna anche il Service Worker (per background updates)
        if (navigator.serviceWorker?.controller) {
            navigator.serviceWorker.controller.postMessage({ type: 'SET_BADGE', count });
        }
    }

    async function refreshBadge(dipId) {
        if (!dipId || !window.supabaseClient) return;
        const today = new Date().toISOString().split('T')[0];
        try {
            // Conta task attivi per oggi (tre query come in giornaliero-dipendente.html)
            const [r1, r2, r3] = await Promise.all([
                window.supabaseClient.from('tasks').select('id', { count: 'exact', head: true })
                    .eq('assigned_user_id', dipId).lte('data_inizio', today).gte('scadenza', today)
                    .not('stato', 'in', '("completato","annullato")'),
                window.supabaseClient.from('tasks').select('id', { count: 'exact', head: true })
                    .eq('assigned_user_id', dipId).is('data_inizio', null).eq('scadenza', today)
                    .not('stato', 'in', '("completato","annullato")'),
                window.supabaseClient.from('tasks').select('id', { count: 'exact', head: true })
                    .eq('assigned_user_id', dipId).eq('data_inizio', today).is('scadenza', null)
                    .not('stato', 'in', '("completato","annullato")'),
            ]);
            const count = (r1.count || 0) + (r2.count || 0) + (r3.count || 0);
            await setBadge(count);
            return count;
        } catch (_) { return 0; }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3 · PUSH NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════
    async function saveSub(sub, dipId) {
        if (!window.supabaseClient) return;
        const s = sub.toJSON();
        await window.supabaseClient.from('push_subscriptions').upsert({
            dipendente_id: dipId,
            endpoint:      s.endpoint,
            key_p256dh:    s.keys.p256dh,
            key_auth:      s.keys.auth,
            user_agent:    navigator.userAgent.substring(0, 200),
            updated_at:    new Date().toISOString()
        }, { onConflict: 'dipendente_id' });
    }

    async function initPush(dipId) {
        if (!dipId) return;
        if (!('Notification' in window)) return;

        // Se già bloccate non chiedere
        if (Notification.permission === 'denied') return;

        // Piccolo delay per non chiedere subito al caricamento
        await new Promise(r => setTimeout(r, 4000));

        // Mostra banner anche se push non supportata (es. Safari non-PWA)
        if (Notification.permission === 'default') {
            const ok = await showNotifBanner();
            if (!ok) return;

            const perm = await Notification.requestPermission();
            if (perm !== 'granted') return;
        }

        // Push subscription: solo se il browser la supporta
        if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
            console.log('[ZGPwa] Permesso notifiche concesso, ma Push API non disponibile (Safari non-PWA)');
            return;
        }

        const reg = await navigator.serviceWorker.ready;

        // Controlla se già iscritto
        const existing = await reg.pushManager.getSubscription();
        if (existing) { await saveSub(existing, dipId); return; }

        // Nuova iscrizione
        try {
            const sub = await reg.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: urlB64ToUint8(VAPID_PUBLIC_KEY)
            });
            await saveSub(sub, dipId);
            console.log('[ZGPwa] ✅ Push subscription attiva');
        } catch (e) {
            console.warn('[ZGPwa] Push subscribe failed:', e);
        }
    }

    // ── Banner "Attiva notifiche" (non-bloccante) ───────────────────────────
    function showNotifBanner() {
        return new Promise(resolve => {
            // Non mostrare se già risposto "Sì" (permesso concesso o già sottoscritto)
            if (localStorage.getItem('zg_notif_granted')) { resolve(false); return; }

            const banner = document.createElement('div');
            banner.id = 'zg-notif-banner';
            banner.innerHTML = `
                <div style="position:fixed;bottom:80px;left:12px;right:12px;z-index:99999;
                            background:#1e293b;color:#fff;border-radius:16px;padding:16px 18px;
                            box-shadow:0 8px 32px rgba(0,0,0,.4);display:flex;align-items:center;gap:12px;
                            animation:slideUp .3s ease-out;">
                    <span style="font-size:28px;">🔔</span>
                    <div style="flex:1">
                        <p style="margin:0;font-weight:700;font-size:15px;">Attiva le notifiche</p>
                        <p style="margin:4px 0 0;font-size:13px;color:#94a3b8;">
                            Ricevi avvisi quando ti vengono assegnate nuove lavorazioni
                        </p>
                    </div>
                    <div style="display:flex;flex-direction:column;gap:8px;flex-shrink:0">
                        <button id="zg-notif-yes" style="background:#7c3aed;color:#fff;border:none;
                            border-radius:8px;padding:8px 16px;font-size:13px;font-weight:600;cursor:pointer;">
                            Sì, attiva
                        </button>
                        <button id="zg-notif-no" style="background:transparent;color:#94a3b8;border:none;
                            font-size:13px;cursor:pointer;">Non ora</button>
                    </div>
                </div>
            `;
            document.body.appendChild(banner);

            document.getElementById('zg-notif-yes').onclick = () => {
                localStorage.setItem('zg_notif_granted', '1');
                banner.remove();
                resolve(true);
            };
            document.getElementById('zg-notif-no').onclick  = () => { banner.remove(); resolve(false); };
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 4 · REALTIME (in-app, quando l'app è aperta)
    // ═══════════════════════════════════════════════════════════════════════
    function subscribeRealtime(dipId, onChange) {
        if (!window.supabaseClient || !dipId) return;

        window.supabaseClient.channel(`zg-tasks-${dipId}`)
            .on('postgres_changes', {
                event:  '*',
                schema: 'public',
                table:  'tasks',
                filter: `assigned_user_id=eq.${dipId}`
            }, payload => {
                console.log('[ZGPwa] Realtime:', payload.eventType, payload.new?.titolo);
                onChange?.(payload);

                // Mostra toast in-app
                const msg = payload.eventType === 'INSERT'
                    ? `📋 Nuova lavorazione: ${payload.new?.titolo || ''}`
                    : `📝 Aggiornamento: ${payload.new?.titolo || ''}`;
                showToast(msg);
            })
            .subscribe();
    }

    // ── Toast in-app ────────────────────────────────────────────────────────
    function showToast(msg, duration = 4000) {
        const t = document.createElement('div');
        t.style.cssText = `
            position:fixed;top:16px;left:50%;transform:translateX(-50%);z-index:99999;
            background:#1e293b;color:#fff;border-radius:12px;padding:12px 20px;
            font-size:14px;font-weight:500;box-shadow:0 4px 20px rgba(0,0,0,.3);
            white-space:nowrap;max-width:90vw;overflow:hidden;text-overflow:ellipsis;
            animation:slideDown .25s ease-out;
        `;
        t.textContent = msg;
        if (!document.getElementById('zg-toast-style')) {
            const s = document.createElement('style');
            s.id = 'zg-toast-style';
            s.textContent = '@keyframes slideDown{from{opacity:0;top:0}to{opacity:1;top:16px}}@keyframes slideUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}';
            document.head.appendChild(s);
        }
        document.body.appendChild(t);
        setTimeout(() => t.remove(), duration);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 5 · ENTRY POINT
    // ═══════════════════════════════════════════════════════════════════════
    async function init(dipId) {
        await registerSW();

        if (dipId) {
            // Badge
            await refreshBadge(dipId);

            // Realtime → aggiorna badge e mostra toast
            subscribeRealtime(dipId, async () => {
                await refreshBadge(dipId);
            });

            // Push (dopo un breve delay per non bloccare il caricamento pagina)
            setTimeout(() => initPush(dipId), 2000);
        }
    }

    // ── Export globale ───────────────────────────────────────────────────────
    window.ZGPwa = { init, setBadge, refreshBadge, showToast };

})();

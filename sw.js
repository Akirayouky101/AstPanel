/**
 * ZG Impianti - Service Worker
 * Gestisce: Offline caching, Push Notifications, Badge API
 */

const CACHE_VERSION = 'v1';
const STATIC_CACHE  = `zg-static-${CACHE_VERSION}`;
const PAGES_CACHE   = `zg-pages-${CACHE_VERSION}`;

const STATIC_ASSETS = [
    '/Admin/icons/icon-192x192.png',
    '/Admin/icons/icon-512x512.png',
    '/mobile-optimizations.css',
    '/supabase-client.js',
];

const CACHED_PAGES = [
    '/giornaliero-dipendente.html',
    '/calendario-dipendente.html',
];

// ===== INSTALL: pre-cache assets =====
self.addEventListener('install', event => {
    self.skipWaiting();
    event.waitUntil(
        Promise.all([
            caches.open(STATIC_CACHE).then(cache => cache.addAll(STATIC_ASSETS).catch(() => {})),
            caches.open(PAGES_CACHE).then(cache =>
                Promise.all(CACHED_PAGES.map(url =>
                    fetch(url).then(r => r.ok ? cache.put(url, r) : null).catch(() => {})
                ))
            )
        ])
    );
});

// ===== ACTIVATE: pulisci cache vecchie =====
self.addEventListener('activate', event => {
    event.waitUntil(
        Promise.all([
            self.clients.claim(),
            caches.keys().then(keys =>
                Promise.all(
                    keys.filter(k => k.startsWith('zg-') && k !== STATIC_CACHE && k !== PAGES_CACHE)
                        .map(k => caches.delete(k))
                )
            )
        ])
    );
});

// ===== FETCH: strategia cache =====
self.addEventListener('fetch', event => {
    const url = new URL(event.request.url);

    // Ignora metodi non-GET
    if (event.request.method !== 'GET') return;

    // Ignora richieste esterne (Supabase, CDN)
    if (url.hostname !== self.location.hostname) return;

    // Per pagine HTML: Network-first → fallback cache
    const isHTML = event.request.headers.get('accept')?.includes('text/html')
                || url.pathname.endsWith('.html')
                || url.pathname === '/';

    if (isHTML) {
        event.respondWith(
            fetch(event.request)
                .then(response => {
                    if (response.ok) {
                        const clone = response.clone();
                        caches.open(PAGES_CACHE).then(c => c.put(event.request, clone));
                    }
                    return response;
                })
                .catch(() =>
                    caches.match(event.request)
                        .then(cached => cached || caches.match('/giornaliero-dipendente.html'))
                )
        );
        return;
    }

    // Per asset statici: Cache-first → network fallback
    event.respondWith(
        caches.match(event.request).then(cached => {
            if (cached) return cached;
            return fetch(event.request).then(response => {
                if (response.ok) {
                    const clone = response.clone();
                    caches.open(STATIC_CACHE).then(c => c.put(event.request, clone));
                }
                return response;
            }).catch(() => new Response('Offline', { status: 503 }));
        })
    );
});

// ===== PUSH: notifiche native =====
self.addEventListener('push', event => {
    if (!event.data) return;

    let payload;
    try { payload = event.data.json(); }
    catch { payload = { title: '🔔 ZG Impianti', body: event.data.text() }; }

    const options = {
        body:             payload.body || 'Hai un aggiornamento',
        icon:             '/Admin/icons/icon-192x192.png',
        badge:            '/Admin/icons/icon-192x192.png',
        tag:              payload.tag  || 'zg-default',
        requireInteraction: payload.requireInteraction || false,
        vibrate:          [200, 100, 200],
        data:             { url: payload.url || '/giornaliero-dipendente.html' },
        actions: [
            { action: 'open',    title: '📂 Apri' },
            { action: 'dismiss', title: 'Ignora' }
        ]
    };

    event.waitUntil(
        self.registration.showNotification(payload.title || '🔔 ZG Impianti', options)
    );
});

// ===== NOTIFICATION CLICK =====
self.addEventListener('notificationclick', event => {
    event.notification.close();
    if (event.action === 'dismiss') return;

    const targetUrl = event.notification.data?.url || '/giornaliero-dipendente.html';

    event.waitUntil(
        self.clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then(clients => {
                const existing = clients.find(c => c.url.includes(targetUrl));
                if (existing) return existing.focus();
                return self.clients.openWindow(targetUrl);
            })
    );
});

// ===== MESSAGGI dalla pagina =====
self.addEventListener('message', event => {
    if (!event.data) return;
    switch (event.data.type) {
        case 'SKIP_WAITING':
            self.skipWaiting();
            break;
        case 'SET_BADGE':
            const count = event.data.count || 0;
            if ('setAppBadge' in self) {
                count > 0 ? self.setAppBadge(count) : self.clearAppBadge();
            }
            break;
    }
});

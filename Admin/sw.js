// ================================================
// AST PANEL - Service Worker v2.1
// Features: Offline Cache + Push Notifications + Background Sync
// ================================================

const CACHE_VERSION = 'ast-panel-v2.1';
const CACHE_STATIC = `${CACHE_VERSION}-static`;
const CACHE_DYNAMIC = `${CACHE_VERSION}-dynamic`;
const CACHE_IMAGES = `${CACHE_VERSION}-images`;

// URLs da cachare immediatamente (static assets)
const STATIC_ASSETS = [
  '/',
  '/pannello-utente.html',
  '/calendario-dipendente.html',
  '/admin-functional.html',
  '/analytics-dashboard.html',
  '/timbratura-veloce.html',
  '/output.css',
  '/Admin/index.html',
  '/Admin/gestione-utenti.html',
  '/Admin/gestione-lavorazioni.html',
  '/Admin/gestione-magazzino.html',
  '/shared-data.js',
  '/supabase-client.js',
  '/modal-system.js',
  '/client-modal.js',
  '/mobile-optimizations.css',
  '/mobile-enhancements.js'
];

// CDN da cachare (librerie esterne)
const CDN_ASSETS = [
  'https://unpkg.com/lucide@latest/dist/umd/lucide.js',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
];

// ========== INSTALL EVENT ==========
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Service Worker v2.1...');
  
  event.waitUntil(
    Promise.all([
      // Cache static assets
      caches.open(CACHE_STATIC).then(cache => {
        console.log('[SW] Caching static assets');
        return cache.addAll(STATIC_ASSETS.concat(CDN_ASSETS));
      }),
      // Skip waiting per attivare immediatamente
      self.skipWaiting()
    ])
  );
});

// ========== ACTIVATE EVENT ==========
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Service Worker v2.1...');
  
  event.waitUntil(
    Promise.all([
      // Pulisci vecchie cache
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames
            .filter(name => name.startsWith('ast-panel-') && name !== CACHE_STATIC)
            .map(name => {
              console.log('[SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      }),
      // Prendi controllo di tutti i client
      self.clients.claim().then(() => {
        // Notifica tutti i client che c'è un aggiornamento
        return self.clients.matchAll().then(clients => {
          clients.forEach(client => {
            client.postMessage({
              type: 'SW_UPDATED',
              version: CACHE_VERSION
            });
          });
        });
      })
    ])
  );
});

// ========== FETCH EVENT - Network First con Fallback Cache ==========
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Ignora richieste non-GET
  if (request.method !== 'GET') return;

  // Ignora richieste Supabase (sempre online)
  if (url.hostname.includes('supabase')) return;

  // Strategy: Network First, fallback to Cache
  event.respondWith(
    fetch(request)
      .then(response => {
        // Clone response per cachare
        const responseClone = response.clone();
        
        // Determina cache da usare
        let cacheName = CACHE_DYNAMIC;
        if (request.destination === 'image') {
          cacheName = CACHE_IMAGES;
        }
        
        // Salva in cache dinamica
        caches.open(cacheName).then(cache => {
          cache.put(request, responseClone);
        });
        
        return response;
      })
      .catch(() => {
        // Network failed, try cache
        return caches.match(request).then(cached => {
          if (cached) {
            console.log('[SW] Serving from cache:', request.url);
            return cached;
          }
          
          // Se non c'è nemmeno in cache, offline page
          if (request.destination === 'document') {
            return caches.match('/pannello-utente.html');
          }
        });
      })
  );
});

// ========== PUSH NOTIFICATION EVENT ==========
self.addEventListener('push', (event) => {
  console.log('[SW] Push notification received', event);
  
  let notificationData = {
    title: 'AST Panel',
    body: 'Nuova notifica',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    tag: 'default',
    data: { url: '/pannello-utente.html' }
  };

  // Parse payload se disponibile
  if (event.data) {
    try {
      const payload = event.data.json();
      notificationData = {
        title: payload.title || notificationData.title,
        body: payload.body || notificationData.body,
        icon: payload.icon || notificationData.icon,
        badge: payload.badge || notificationData.badge,
        tag: payload.tag || notificationData.tag,
        vibrate: payload.vibrate || [200, 100, 200],
        data: payload.data || notificationData.data,
        actions: payload.actions || [
          { action: 'open', title: '👀 Apri', icon: '/icons/open.png' },
          { action: 'close', title: '❌ Chiudi', icon: '/icons/close.png' }
        ],
        requireInteraction: payload.requireInteraction || false
      };
    } catch (e) {
      console.error('[SW] Error parsing push payload:', e);
    }
  }

  event.waitUntil(
    self.registration.showNotification(notificationData.title, {
      body: notificationData.body,
      icon: notificationData.icon,
      badge: notificationData.badge,
      tag: notificationData.tag,
      vibrate: notificationData.vibrate,
      data: notificationData.data,
      actions: notificationData.actions,
      requireInteraction: notificationData.requireInteraction
    })
  );
});

// ========== NOTIFICATION CLICK EVENT ==========
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event.action);
  
  event.notification.close();

  if (event.action === 'close') {
    return; // Solo chiudi
  }

  // Apri o focus sulla finestra
  const urlToOpen = event.notification.data?.url || '/pannello-utente.html';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        // Cerca finestra già aperta
        for (let client of windowClients) {
          if (client.url.includes(urlToOpen) && 'focus' in client) {
            return client.focus();
          }
        }
        
        // Apri nuova finestra
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// ========== BACKGROUND SYNC EVENT ==========
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync triggered:', event.tag);
  
  if (event.tag === 'sync-lavorazioni') {
    event.waitUntil(syncPendingData());
  }
});

// Funzione per sincronizzare dati pending
async function syncPendingData() {
  try {
    const cache = await caches.open('pending-requests');
    const requests = await cache.keys();
    
    console.log(`[SW] Syncing ${requests.length} pending requests`);
    
    const results = await Promise.allSettled(
      requests.map(async (request) => {
        try {
          const response = await fetch(request.clone());
          if (response.ok) {
            await cache.delete(request);
            console.log('[SW] Synced:', request.url);
          }
          return response;
        } catch (error) {
          console.warn('[SW] Sync failed for:', request.url, error);
          throw error;
        }
      })
    );
    
    const successful = results.filter(r => r.status === 'fulfilled').length;
    console.log(`[SW] Sync completed: ${successful}/${requests.length} successful`);
    
    // Notifica utente del sync completato
    if (successful > 0) {
      await self.registration.showNotification('Sincronizzazione Completata', {
        body: `${successful} elementi sincronizzati con successo`,
        icon: '/icons/icon-192x192.png',
        tag: 'sync-complete'
      });
    }
    
  } catch (error) {
    console.error('[SW] Background sync error:', error);
    throw error;
  }
}

// ========== MESSAGE EVENT (comunicazione con client) ==========
self.addEventListener('message', (event) => {
  console.log('[SW] Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(name => caches.delete(name))
        );
      }).then(() => {
        event.ports[0].postMessage({ success: true });
      })
    );
  }
});

console.log('[SW] Service Worker v2.0 loaded successfully!');

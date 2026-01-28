// Service Worker per Magazzino PWA
const CACHE_NAME = 'magazzino-v1';
const urlsToCache = [
  '/magazzino-semplice.html',
  '/supabase-client.js',
  '/Admin/auth-helper.js',
  'https://cdn.tailwindcss.com',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css',
  'https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js',
  'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js',
  'https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js'
];

// Installazione
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

// Fetch con strategia Network First (per dati sempre aggiornati)
self.addEventListener('fetch', event => {
  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Clona la risposta
        const responseToCache = response.clone();
        
        // Salva in cache
        caches.open(CACHE_NAME)
          .then(cache => cache.put(event.request, responseToCache));
        
        return response;
      })
      .catch(() => {
        // Se offline, usa cache
        return caches.match(event.request);
      })
  );
});

// Pulizia vecchie cache
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

const CACHE_NAME = 'ast-panel-v1';
const urlsToCache = [
  '/Admin/index.html',
  '/Admin/gestione-utenti.html',
  '/Admin/gestione-lavorazioni.html',
  '/Admin/gestione-magazzino.html'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

/* Minimaler Service Worker – ohne ihn ist KEINE PWA-Installation möglich. */
const CACHE = 'pwa-cache-v3';
const ASSETS = [
  './',
  './index.html',
  './pwa-install.html',
  './ios-install.gif',
  './ios26-install.gif',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

// Installieren: Grunddateien in den Cache legen
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Alte Caches aufräumen
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Cache-first: macht die App offlinefähig (Voraussetzung für „Installierbar")
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then((cached) =>
      cached || fetch(event.request).catch(() => caches.match('./index.html'))
    )
  );
});

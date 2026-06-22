/* Service Worker – NETWORK-FIRST.
 *
 * Frueher war die Strategie "cache-first": alte Inhalte (z. B. ein altes GIF)
 * blieben auf Geraeten haengen, weil immer zuerst der Cache geliefert wurde.
 * Jetzt wird IMMER zuerst das Netz versucht; der Cache dient nur als
 * Offline-Fallback. So kommen Updates zuverlaessig an. */
const CACHE = 'pwa-cache-v4';
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

// Installieren: Grunddateien fuer den Offline-Fall vorladen
self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)));
  self.skipWaiting();
});

// Aktivieren: ALLE alten Caches loeschen (ausser dem aktuellen), Clients uebernehmen
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Network-first: erst Netz, dann (nur offline) Cache
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request)
      .then((resp) => {
        const copy = resp.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy)).catch(() => {});
        return resp;
      })
      .catch(() =>
        caches.match(event.request, { ignoreSearch: true })
          .then((cached) => cached || caches.match('./index.html'))
      )
  );
});

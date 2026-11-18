// Color Pallete Offline Service Worker
// Cache-first strategy with background revalidation for maximum loading speed

const CACHE_NAME = 'color-pallete-cache-v2';

// Essential assets to cache immediately upon service worker installation
const CORE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'version.json',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/colors.json',
  'assets/FontManifest.json',
  'assets/AssetManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/icon.png'
];

// Install Event: pre-cache static assets
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      console.log('[Color Pallete SW] Pre-caching static assets for offline use...');
      await Promise.allSettled(
        CORE_ASSETS.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch((err) => {
            console.warn('[Color Pallete SW] Could not precache:', url, err);
          })
        )
      );
    })
  );
});

// Activate Event: clean up older caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[Color Pallete SW] Deleting older cache:', key);
            return caches.delete(key);
          }
        })
      )
    ).then(() => self.clients.claim())
  );
});

// Fetch Event: Cache-First strategy with background update
self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Ignore non-GET requests or chrome-extension URLs
  if (request.method !== 'GET' || !request.url.startsWith('http')) {
    return;
  }

  // Do not intercept third-party ad networks
  if (
    request.url.includes('googlesyndication.com') ||
    request.url.includes('googleads') ||
    request.url.includes('doubleclick.net')
  ) {
    return;
  }

  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      // Revalidate in background to keep cache fresh
      const fetchPromise = fetch(request)
        .then((networkResponse) => {
          if (
            networkResponse &&
            networkResponse.status === 200 &&
            networkResponse.type !== 'opaque'
          ) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(request, responseClone);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          // If offline and request is HTML navigation, fallback to cached index.html
          if (request.mode === 'navigate') {
            return caches.match('index.html') || caches.match('./');
          }
          return null;
        });

      // Return cached version immediately if found, else wait for network
      return cachedResponse || fetchPromise;
    })
  );
});

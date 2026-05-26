// AlSaeb CRM - Service Worker v2
const CACHE = 'alsaeb-v2';
const SHELL = [
  '/agent',
  '/game',
  '/static/manifest.json',
];
// CDN assets cached on first use
const CDN_HOSTS = ['cdn.jsdelivr.net', 'cdn.tailwindcss.com', 'unpkg.com', 'fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // Network-first for API calls — return offline fallback if network fails
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(
      fetch(e.request).catch(() => new Response(JSON.stringify({ offline: true, status: 'error', message: 'أنت أوفلاين' }), {
        status: 503, headers: { 'Content-Type': 'application/json' },
      }))
    );
    return;
  }

  // Cache-first for CDN assets (Tailwind, Phaser, Supabase JS, fonts)
  if (CDN_HOSTS.some((h) => url.hostname.includes(h))) {
    e.respondWith(
      caches.match(e.request).then((cached) =>
        cached || fetch(e.request).then((res) => {
          if (res.ok) {
            const clone = res.clone();
            caches.open(CACHE).then((c) => c.put(e.request, clone));
          }
          return res;
        })
      )
    );
    return;
  }

  // Stale-while-revalidate for app pages and static assets
  if (e.request.method === 'GET') {
    e.respondWith(
      caches.match(e.request).then((cached) => {
        const networkFetch = fetch(e.request).then((res) => {
          if (res.ok) {
            const clone = res.clone();
            caches.open(CACHE).then((c) => c.put(e.request, clone));
          }
          return res;
        }).catch(() => cached);
        return cached || networkFetch;
      })
    );
  }
});

// ==================== Push Notifications ====================
self.addEventListener('push', (e) => {
  let data = { title: 'AlSaeb CRM', body: 'لديك إشعار جديد', url: '/agent' };
  try {
    if (e.data) data = Object.assign(data, e.data.json());
  } catch (_) {}
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/static/icon-192.png',
      badge: '/static/icon-192.png',
      tag: 'crm-push-' + Date.now(),
      data: { url: data.url || '/agent' },
      vibrate: [200, 100, 200],
      requireInteraction: true,
    })
  );
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const url = (e.notification.data && e.notification.data.url) || '/agent';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if (c.url.includes('/agent') && 'focus' in c) return c.focus();
      }
      return clients.openWindow(url);
    })
  );
});

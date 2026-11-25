// Service worker mínimo: permite instalar la app. No guarda copias (siempre usa la versión publicada).
self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(self.clients.claim()));
self.addEventListener('fetch',()=>{});

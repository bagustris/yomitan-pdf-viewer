// update.sh replaces this with the PDF.js release being packaged. Keeping the
// release in the cache name ensures that an updated viewer cannot keep serving
// files from an older distribution.
const CACHE_NAME = "yomitan-pdf-viewer-pdfjs-4.10.38";
const APP_SHELL = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./pwa-register.js",
  "./icons/icon-192.svg",
  "./icons/icon-512.svg",
  "./build/pdf.mjs",
  "./build/pdf.worker.mjs",
  "./build/pdf.sandbox.mjs",
  "./web/",
  "./web/index.html",
  "./web/viewer.css",
  "./web/viewer.mjs",
  "./web/locale/locale.json",
  "./web/yomitan-pdf-viewer.pdf"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) =>
        Promise.all(
          cacheNames
            .filter((cacheName) => cacheName.startsWith("yomitan-pdf-viewer-"))
            .filter((cacheName) => cacheName !== CACHE_NAME)
            .map((cacheName) => caches.delete(cacheName))
        )
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") {
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request)
        .then((response) => {
          // PDFs may be supplied by a local server and change independently of
          // the viewer. Do not make those documents cache-first; the bundled
          // PDF is already part of APP_SHELL.
          if (response.ok && !requestUrl.pathname.endsWith(".pdf")) {
            const responseCopy = response.clone();
            event.waitUntil(
              caches
                .open(CACHE_NAME)
                .then((cache) => cache.put(event.request, responseCopy))
                .catch(() => {
                  // A cache write must not turn a successful request into a failure.
                })
            );
          }
          return response;
        })
        .catch(() => {
          if (event.request.mode === "navigate") {
            return caches.match(new URL("./web/index.html", self.location.href));
          }
          return Response.error();
        });
    })
  );
});

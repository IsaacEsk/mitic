'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "0aa2dd65d560a5cf86cab823bf9c8472",
"assets/AssetManifest.bin.json": "2e34e12273cab1070c08572534abca2c",
"assets/AssetManifest.json": "4527b93b07695330daf28659fb6f8b66",
"assets/assets/data/civilizaciones.json": "e300f70544d1d72ced3826c7e7247198",
"assets/assets/data/en.json": "b80ce2842618fc25d3288d2c1fcdf64b",
"assets/assets/data/es.json": "c50bda3e944b66354ec407bc5bcb80e1",
"assets/assets/data/personajes.json": "f93c5080613306cf35e29a82f975109e",
"assets/assets/images/dados/1x1.png": "829d53795cd88fce69a715c1cf505909",
"assets/assets/images/dados/1x2.png": "8e1c412901ce17f8118c9a6ecb4c30a3",
"assets/assets/images/dados/1x3.png": "116d05f5d11451f82b086b063dd38380",
"assets/assets/images/dados/1x4.png": "9885af0e6b792611cc39fc6fb017b49c",
"assets/assets/images/dados/1x5.png": "d55f36796593d577ae3ebc4256a71a07",
"assets/assets/images/dados/1x6.png": "4f692bc7b88ebacd9acde2b7545e53af",
"assets/assets/images/dados/2x1.png": "79e1717de024b09e499ea4d9e1be06c8",
"assets/assets/images/dados/2x2.png": "47401b09c50e4ff28263685d05c62377",
"assets/assets/images/dados/2x3.png": "3d68b648969ddfbbfaf230c6a39e2cee",
"assets/assets/images/dados/2x4.png": "633a70196f707c415e30644828bcdf3b",
"assets/assets/images/dados/2x5.png": "c15c5f2004340cfd00167f6638f72a26",
"assets/assets/images/dados/2x6.png": "3b2bd8e282d77d3390dd1a4602263129",
"assets/assets/images/dados/3x1.png": "12ff74a4a3f1d69484a43e69ed2c3ded",
"assets/assets/images/dados/3x2.png": "efb93993af7c0101ce41f070e308dbc2",
"assets/assets/images/dados/3x3.png": "77033c7371e405e8db0f5d2f26bf5e5e",
"assets/assets/images/dados/3x4.png": "5613beb734d6d3df8f9fa4bea7618922",
"assets/assets/images/dados/3x5.png": "18a8b87d178cfa15d7bae3cbee1a845f",
"assets/assets/images/dados/3x6.png": "1d65a20ed489ec46c4170eda73e25382",
"assets/assets/images/dados/4x1.png": "d715bc3f230311e5afd0c586ff87177e",
"assets/assets/images/dados/4x2.png": "438bf9c04a5c477476ba1b63612869ca",
"assets/assets/images/dados/4x3.png": "792084104708f9cd0a095564a50bc3e7",
"assets/assets/images/dados/4x4.png": "b02c28be0045ccd7c636e4f86c7d53d1",
"assets/assets/images/dados/4x5.png": "a7cb9834543b2f0b9cde6018ffeef064",
"assets/assets/images/dados/4x6.png": "89626bf686d449e85904e66d52e3e86a",
"assets/assets/images/dados/5x1.png": "73e640f57f423fad908d8c5e375d7241",
"assets/assets/images/dados/5x2.png": "2e401b6932c543e1de630163102a3d9e",
"assets/assets/images/dados/5x3.png": "80daa07f35d4a5b34eb53eb4d391dd4d",
"assets/assets/images/dados/5x4.png": "450046cc6ec4cc12dc18d0b05bf0e83c",
"assets/assets/images/dados/5x5.png": "e5ccf49f4ac99ceb69a1dd1ce7dc4b5c",
"assets/assets/images/dados/5x6.png": "409cfbb334f480c338e9e6ca636f98aa",
"assets/assets/images/dados/6x1.png": "0863038e97c5d966a0c04223245e2523",
"assets/assets/images/dados/6x2.png": "31b3381168af5e8af51b8dd95e8102da",
"assets/assets/images/dados/6x3.png": "ee3ba28b960762ea1b3a978a1e0b1223",
"assets/assets/images/dados/6x4.png": "988c8d738dc9555fb3a8c5c0f421c9d0",
"assets/assets/images/dados/6x5.png": "2cfd711a9d1cd6322d1b7b5b2aa7935b",
"assets/assets/images/dados/6x6.png": "a9999f729f284f31896aecfadc3a2a0c",
"assets/assets/images/monumentos/castillo_osaka.png": "ddeb5edd9ed23b20effda90a6aadbdf8",
"assets/assets/images/monumentos/chichen_itza.png": "bec9945226a2a388def2dcef6fae2ba7",
"assets/assets/images/monumentos/coliseo.png": "f8335f08feccfefb6f85deb61499de26",
"assets/assets/images/monumentos/mezquita.png": "9e8549e3054c2815f320eb034c7e73ae",
"assets/assets/images/monumentos/murallas_jerusalen.png": "1f021e1312fc07cfc233a8f3f0cf430d",
"assets/assets/images/monumentos/muralla_china.png": "5baf5f19e32c8a322289bfc62c9645f6",
"assets/assets/images/monumentos/piramides.png": "11257dbc8de4dbf4923c715c686f10ad",
"assets/assets/images/monumentos/taj_mahal.png": "0a6f8f916a632b9b6c2af905d4983a8c",
"assets/assets/images/monumentos/templo_mayor.png": "7949fa156ab9b06592a9117b4859d5cc",
"assets/assets/images/monumentos/torre_eiffel.png": "507564eb17670931d96fd424bc0f4df8",
"assets/assets/images/personajes/anubis.png": "e82b43064dbf1a7570166c8725799c81",
"assets/assets/images/personajes/ganesha.png": "a60761bb3ed60592ffbe35137db59aaf",
"assets/assets/images/personajes/gladiador.png": "ebd93e549ac644b3a9c286114c8abe1e",
"assets/assets/images/personajes/huitzilopochtli.png": "fc44c69871c6192bc3f3de6196407f46",
"assets/assets/images/personajes/juana_de_arco.png": "9ed872ce2d0c1375c723feb86e47ccc9",
"assets/assets/images/personajes/kukulkan.png": "7e2531e40687bb172369518b86fa7b1f",
"assets/assets/images/personajes/saladino.png": "100966b317f083324edeaafb58982ad1",
"assets/assets/images/personajes/samurai.png": "241adef38a8825c0f7b2958d95d24e61",
"assets/assets/images/personajes/templario.png": "e701a11eea08674c09fb624d7e99e90d",
"assets/assets/images/personajes/terracota.png": "c27d274120a84593ddab90b3d5659dac",
"assets/FontManifest.json": "1b1e7812d9eb9f666db8444d7dde1b20",
"assets/fonts/MaterialIcons-Regular.otf": "36b47fa9b0c560ea0464783fd374ef62",
"assets/NOTICES": "384fe1cf1aa6e2ee58b6969cb1b86ba3",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/material_design_icons_flutter/lib/fonts/materialdesignicons-webfont.ttf": "d10ac4ee5ebe8c8fff90505150ba2a76",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "7320a40992888a92018ae03970c1672d",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "215fb205ca1d23b245d1d4b2f80faf6a",
"/": "215fb205ca1d23b245d1d4b2f80faf6a",
"main.dart.js": "d69b452a202c463141837c9aa4601bb4",
"manifest.json": "b54293573e0e6c7c275e3d10aa8a42ff",
"version.json": "301034ed818c925eef89cad8e9d1c175"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "7d69e653079438abfbb24b82a655b0a4",
"manifest.json": "d4210f48e7574e423372c165ac06f628",
"index.html": "108636e7abbd933598e0c7e03aba5b5e",
"/": "108636e7abbd933598e0c7e03aba5b5e",
"assets/AssetManifest.bin": "0702b87391056752bbb5c1cff0e40a9e",
"assets/fonts/MaterialIcons-Regular.otf": "32fce58e2acb9c420eab0fe7b828b761",
"assets/assets/images/joystick_knob.png": "bb0811554c35e7d74df6d80fb5ff5cd5",
"assets/assets/images/redar_head.png": "4dbc55bc5281e66a45e7e6bec8ee7a5c",
"assets/assets/images/bullet.png": "1f1d1c414b11cb0e94305854417b359e",
"assets/assets/images/ground_tiles.png": "7ad67f22e1c795c7d9450c86ea7bf089",
"assets/assets/images/brick_tiles.png": "8b50bfc28457374a63dbe7cc3d511315",
"assets/assets/images/tiles.png": "77a1b8c8d265d20b6156e973ceaec445",
"assets/assets/images/joystick_background.png": "8c9aa78348b48e03f06bb97f74b819c9",
"assets/assets/images/noise.gif": "66307fd1e8069548c1e47a68c129cd1b",
"assets/assets/images/classic.json": "5c3e6a86d2768c107d05d349d5cad7ea",
"assets/assets/images/joystick_atack_range.png": "8994f23fc67442c8361432f0cc9a2fa1",
"assets/assets/images/spritesheets/tank_basic2.png": "ded2f589c7def97c8ef1799383b9dbfe",
"assets/assets/images/spritesheets/fire.png": "f09897515bc1d486b66667ef545b41ce",
"assets/assets/images/spritesheets/target.png": "fd63718f02599db944197540d879b96c",
"assets/assets/images/spritesheets/bullet.png": "e03db7a93bf144294f63f91098c5cd3b",
"assets/assets/images/spritesheets/spawn.png": "64143712896adcc8a4d95f8b07f4fe6b",
"assets/assets/images/spritesheets/boom.png": "b0f2ce9af8d057d503557b4199faf1c7",
"assets/assets/images/spritesheets/boom_big.png": "5f667b0d231e1eb8d8a6da8195545832",
"assets/assets/images/joystick.png": "e66ba55553b133af7d06f25ef92318db",
"assets/assets/fonts/PTMono55.ttf": "49b13300202f25c085c731d216fab421",
"assets/assets/fonts/kongtext.ttf": "6d6b5f51e552a050d2357c0cb91a400c",
"assets/assets/audio/music/intro.m4a": "8d01f33963d8f8e8d7ba2be9ce4d8858",
"assets/assets/audio/sfx/move_enemies.m4a": "b99d050d08707fb8b53ee4dcdf211db2",
"assets/assets/audio/sfx/player_bullet_strong_wall.m4a": "12c52c37091e9f9631567e51685e44a7",
"assets/assets/audio/sfx/player_fire_bullet.m4a": "f632fcb5daa1f97b4383e958d378ef17",
"assets/assets/audio/sfx/human_step_grass.m4a": "dcf693c42916c107679dacbbb0c5b040",
"assets/assets/audio/sfx/bullet_strong_tank.m4a": "85b4390798772561a5533fcca68062e7",
"assets/assets/audio/sfx/human_death.m4a": "b784934b5a229ad3880c60e260385021",
"assets/assets/audio/sfx/human_shoot.m4a": "156502ea3a7445b1ea9c4ba12a946994",
"assets/assets/audio/sfx/explosion_player.m4a": "18fc2de1acce0d79b4cacb8dcd8fcc2b",
"assets/assets/audio/sfx/2%2520-%2520Track%25202.mp3": "dae2ef3d65b4e3edaf9326c4b5bd7242",
"assets/assets/audio/sfx/move_player.m4a": "75d6da5c666159c95162350326ecbf39",
"assets/assets/audio/sfx/explosion_enemy.m4a": "db0c2899d9bd88f70d10648428fbcd1a",
"assets/assets/audio/sfx/player_bullet_wall.m4a": "3bb2d7bd39a484d0b9e8a367baf94569",
"assets/assets/tiles/north_east_forest.tmx": "ce163a63416b8c5600ad7968b5f54425",
"assets/assets/tiles/radar_head.tsx": "847f152a8241c559e3da5c35b491ad0d",
"assets/assets/tiles/bricks.tsx": "771e057edccabb902172b61b974f52a5",
"assets/assets/tiles/movement_debug.tmx": "cd24937f6e6ac6165a75a50080ae38e1",
"assets/assets/tiles/tutorial_left_top.tmx": "2b5907ac0451a76939afa1fe2f28b96a",
"assets/assets/tiles/tutorial_top_top.tmx": "714ac6cdf75a78f21b98ddb92587ba7c",
"assets/assets/tiles/tutorial_left_left.tmx": "7b445b82841b8d8d506e3a5c175bd730",
"assets/assets/tiles/boom.tsx": "fcfd2c887d55600453e8c66df70cfcb6",
"assets/assets/tiles/tutorial_left_left_bottom.tmx": "83e56e748b5cea451d7034f3345568fe",
"assets/assets/tiles/mission1.tmx": "798e8addef8e35fe3482c1024efd31db",
"assets/assets/tiles/west_forest.tmx": "267fbfb20d6d5f983a684c4f26d195a9",
"assets/assets/tiles/east_forest.tmx": "5c4ea4c2ee233b94910da9643cc5c296",
"assets/assets/tiles/tutorial_top_right.tmx": "1ce3b93d9b26f191ac1f12fed8148d6a",
"assets/assets/tiles/demo.world": "f85a6d158049645e7f32b9ec770dd345",
"assets/assets/tiles/bullet.tsx": "9e2026341494be1e6fc4f08175f51d15",
"assets/assets/tiles/tutorial_bottom.tmx": "cf7272f31179c641234921b7ea68f42a",
"assets/assets/tiles/spawn.tsx": "e49266f288a7325e5904c241932f0863",
"assets/assets/tiles/tutorial_bottom_bottom_bottom.tmx": "15a4eac2525745b6cdeba4c4a163205e",
"assets/assets/tiles/boom_big.tsx": "1821e108574a5fd2a73464b23e981de4",
"assets/assets/tiles/cell_test.tmx": "664181e2811f01f2d24f71edeacca578",
"assets/assets/tiles/tutorial_top.tmx": "d1d8e0a18869209c62ae8112ab24b0e3",
"assets/assets/tiles/lake_south_west.tmx": "ea876594d096c562826437c6884af2ba",
"assets/assets/tiles/tutorial_bottom_bottom.tmx": "1cda4aa3566d1c0b380739672f2d138b",
"assets/assets/tiles/mission.tmx": "6265372f8aa8fad109e77f0983745241",
"assets/assets/tiles/tutorial_left_bottom.tmx": "578c0463360738737c744abb7fc44102",
"assets/assets/tiles/ground.tsx": "565672d50e321429737e5bc1bede2b6b",
"assets/assets/tiles/tutorial.world": "39cf74f580ef45f09f2dfef04b518a81",
"assets/assets/tiles/fire.tsx": "6ec8d4aa5dc8a20d5580f02c388617aa",
"assets/assets/tiles/tutorial_right_bottom.tmx": "84e0721e3ff7e0a78e2728b52444fb9d",
"assets/assets/tiles/target.tsx": "a6d8c03821eae14ac6bca6ce038653f4",
"assets/assets/tiles/tutorial.tmx": "7207f8aee780360572c56b04c83d4445",
"assets/assets/tiles/tank.tsx": "98129fc94ab48b397a04222de052a764",
"assets/assets/tiles/tutorial_right.tmx": "c2ce985cfe3f43d893f39e41a4af13cd",
"assets/assets/tiles/nord_forest.tmx": "700c582dbe619db64df2ab892ead9a0f",
"assets/assets/tiles/tutorial_left.tmx": "58a7b250d00ee9ad0de1648e5da90025",
"assets/assets/tiles/lake.tmx": "1b10d6ae95a2c5be5761d5b777b7b670",
"assets/AssetManifest.bin.json": "7b325fc7801966e4b471f5bd2388ce3f",
"assets/FontManifest.json": "7c1df78bc89e2f08b6c1c7d92d4797de",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"assets/NOTICES": "8f1d00d1a30b1a83b8a5de8a962021b4",
"assets/AssetManifest.json": "059cdefa71560cfcd4166fdd19a21e44",
"assets/packages/nes_ui/google_fonts/PressStart2P-Regular.ttf": "f98cd910425bf727bd54ce767a9b6884",
"assets/packages/nes_ui/google_fonts/OFL.txt": "5096248a0ad125929b038a264f57b570",
"assets/packages/wakelock_web/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"spatial_grid_optimizer_worker.js": "52e500456bd30d861c6404342f870164",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"spatial_grid_optimizer_worker.js.map": "9cc384b3a60bb8bc7c9144228f0ebd07",
"spatial_grid_optimizer_worker.js.deps": "12f4ab68dac3f6a44e94e2deb5442356",
"main.dart.js": "12e226cf1f04655837293674b9d3f67f",
"howler.min.js": "5e24edc86f97b2460c4d12d5d1b4c394",
"version.json": "f6aaec20ff11f3d534d6f39070a7f23b",
"canvaskit/canvaskit.wasm": "73584c1a3367e3eaf757647a8f5c5989",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"canvaskit/skwasm.wasm": "2fc47c0a0c3c7af8542b601634fe9674",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/chromium/canvaskit.wasm": "143af6ff368f9cd21c863bfa4274c406",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
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

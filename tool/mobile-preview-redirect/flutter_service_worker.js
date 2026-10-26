// Retire the cached mock worker without forcing an installed app off origin.
// Existing tabs/drafts are not reloaded; the next normal launch gets the guide.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
  })());
});

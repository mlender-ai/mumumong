{{flutter_js}}
{{flutter_build_config}}

(() => {
  // The engine is already included in this release. Do not require a second
  // origin (gstatic) to make an installed app's first frame possible.
  const config = {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  };
  const fail = () => window.mumumongStartup?.fail();
  _flutter.loader.load({
    config,
    // Preserve Flutter's one-time retirement of legacy caching workers.
    // This is not offline support and never clears IndexedDB or auth data.
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
    onEntrypointLoaded: async (initializer) => {
      try {
        const runner = await initializer.initializeEngine(config);
        await runner.runApp();
      } catch (_) {
        fail();
      }
    },
  }).catch(fail);
})();

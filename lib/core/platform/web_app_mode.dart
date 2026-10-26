import 'web_app_mode_stub.dart'
    if (dart.library.js_interop) 'web_app_mode_browser.dart'
    as platform;

bool get isInstalledWebApp => platform.isInstalledWebApp;

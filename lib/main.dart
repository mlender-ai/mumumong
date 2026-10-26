import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/design/design_system.dart';
import 'core/design/dream_atmosphere.dart';
import 'core/env/env.dart';
import 'data/auth/secure_session_storage.dart';
import 'di/providers.dart';
import 'domain/repository/mumumong_repository.dart';
import 'ui/archive/archive_screen.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/capture/capture_flow.dart';
import 'ui/home/home_screen.dart';
import 'ui/reader/reader_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/settings/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      // Web uses Supabase's default localStorage implementation so a trial
      // account survives reloads. Native sessions stay in Keychain.
      localStorage: kIsWeb ? null : SecureSessionStorage(),
    ),
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: MongColor.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      child: MumumongApp(
        requireAuthentication:
            AppEnv.authentication == AppAuthenticationMode.apple,
      ),
    ),
  );
}

class MumumongApp extends ConsumerWidget {
  const MumumongApp({super.key, this.requireAuthentication = false});

  final bool requireAuthentication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(uiPreferencesProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '무무몽',
      theme: mumumongTheme(),
      darkTheme: dreamNightTheme(),
      themeMode: preferences.themeMode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: context.isNight
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: context.isNight
              ? Brightness.dark
              : Brightness.light,
          systemNavigationBarColor: context.canvas,
          systemNavigationBarIconBrightness: context.isNight
              ? Brightness.light
              : Brightness.dark,
        ),
        child: child!,
      ),
      home: AppLockGate(
        child: requireAuthentication
            ? const AuthGate(manuscript: MumumongShell())
            : const MumumongShell(),
      ),
    );
  }
}

class MumumongShell extends ConsumerStatefulWidget {
  const MumumongShell({super.key, this.settingsPage});

  final Widget? settingsPage;

  @override
  ConsumerState<MumumongShell> createState() => _MumumongShellState();
}

class _MumumongShellState extends ConsumerState<MumumongShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Auth/consent owns this shell. Keep recovery subscribed even while a
    // pushed Reader/settings route pauses this shell's TickerMode consumers.
    ref.listenManual(generationRecoveryProvider, (_, _) {});
    ref.listenManual(libraryReturnHomeProvider, (_, _) {
      if (mounted) setState(() => _tab = 0);
    });
  }

  Future<void> _openCapture() async {
    var volume = ref.read(activeVolumeProvider).value;
    if (volume == null) {
      await Navigator.of(context).push(
        quietPageRoute(
          VolumeSetupScreen(onComplete: () => Navigator.of(context).pop()),
        ),
      );
      if (!mounted) return;
      volume = await ref.read(repositoryProvider).watchActiveVolume().first;
      if (volume == null || !mounted) return;
    }
    final dreams = ref.read(dreamsProvider(DreamStatusFilter.all)).value;
    final scenes = ref.read(scenesProvider(volume.id)).value;
    final created = await Navigator.of(context).push<bool>(
      quietPageRoute(
        CaptureFlow(
          dreamNumber: (dreams?.length ?? 0) + 1,
          sceneNumber: (scenes?.length ?? 0) + 1,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _tab = 0;
      });
    }
  }

  Future<void> _openReader({String? sceneId}) async {
    final volume = ref.read(activeVolumeProvider).value;
    if (volume == null) return;
    await Navigator.of(context).push(
      quietPageRoute(
        ReaderScreen(
          volumeId: volume.id,
          initialSceneId: sceneId,
          onCapture: _openCapture,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AuthGate only mounts the manuscript after current AI consent is confirmed.
    // Starting delivery before that would race the onboarding consent screen.
    ref.watch(outboxWorkerProvider);
    final pages = <Widget>[
      HomeScreen(
        isActive: _tab == 0,
        onCapture: _openCapture,
        onRead: _openReader,
        onReadScene: (id) => _openReader(sceneId: id),
        onArchive: () => setState(() => _tab = 1),
      ),
      ArchiveScreen(onCapture: _openCapture),
      widget.settingsPage ?? const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: MongBottomNav(
        labels: const ['원고', '보관함', '설정'],
        selectedIndex: _tab,
        onSelect: (index) => setState(() => _tab = index),
      ),
    );
  }
}

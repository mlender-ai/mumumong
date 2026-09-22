import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/design/design_system.dart';
import 'core/env/env.dart';
import 'data/auth/secure_session_storage.dart';
import 'di/providers.dart';
import 'domain/repository/mumumong_repository.dart';
import 'ui/archive/archive_screen.dart';
import 'ui/auth/auth_gate.dart';
import 'ui/capture/capture_flow.dart';
import 'ui/home/home_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/settings/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: kIsWeb ? const EmptyLocalStorage() : SecureSessionStorage(),
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

class MumumongApp extends StatelessWidget {
  const MumumongApp({super.key, this.requireAuthentication = false});

  final bool requireAuthentication;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '무무몽',
      theme: mumumongTheme(),
      home: AppLockGate(
        child: requireAuthentication
            ? const AuthGate(manuscript: MumumongShell())
            : const MumumongShell(),
      ),
    );
  }
}

class MumumongShell extends ConsumerStatefulWidget {
  const MumumongShell({super.key});

  @override
  ConsumerState<MumumongShell> createState() => _MumumongShellState();
}

class _MumumongShellState extends ConsumerState<MumumongShell> {
  int _tab = 0;

  Future<void> _openCapture() async {
    final volume = ref.read(activeVolumeProvider).value;
    if (volume == null) {
      return;
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onCapture: _openCapture),
      ArchiveScreen(onCapture: _openCapture),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: MongColor.paper,
          border: Border(top: BorderSide(color: MongColor.line, width: .5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _BottomTab(
                  label: '원고',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _BottomTab(
                  label: '보관함',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _BottomTab(
                  label: '설정',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: MongMotion.micro,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected ? MongColor.ink : MongColor.ink3,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

// MUMUMONG V2 app shell. Same responsibilities as V1 MumumongShell (recovery
// subscription, outbox worker, capture/reader routing); new presentation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../domain/repository/mumumong_repository.dart';
import 'components/navigation.dart';
import 'design/atmosphere.dart';
import 'design/theme.dart';
import 'design/tokens.dart';
import 'screens/archive.dart';
import 'screens/capture.dart';
import 'screens/home.dart';
import 'screens/reader.dart';
import 'screens/reading_settings.dart';
import 'screens/volume_setup.dart';

class MumumongV2App extends StatelessWidget {
  const MumumongV2App({super.key, required this.home, this.overlay});

  final Widget home;

  /// Drawn above every route (the preview marker).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '무무몽',
      theme: v2Theme(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: V2Color.paper,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: overlay == null
            ? child!
            : Stack(
                children: [
                  child!,
                  Positioned.fill(child: IgnorePointer(child: overlay!)),
                ],
              ),
      ),
      home: home,
    );
  }
}

class V2Shell extends ConsumerStatefulWidget {
  const V2Shell({super.key, this.extraSettings});

  /// Extra rows for the settings sheet (the preview's restart action).
  final Widget? extraSettings;

  @override
  ConsumerState<V2Shell> createState() => _V2ShellState();
}

class _V2ShellState extends ConsumerState<V2Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(generationRecoveryProvider, (_, _) {});
    ref.listenManual(libraryReturnHomeProvider, (_, _) {
      if (mounted) setState(() => _tab = 0);
    });
  }

  Future<void> _openCapture() async {
    var volume = ref.read(activeVolumeProvider).value;
    if (volume == null) {
      await Navigator.of(context).push(
        v2Route(
          V2VolumeSetupScreen(onComplete: () => Navigator.of(context).pop()),
        ),
      );
      if (!mounted) return;
      volume = await ref.read(repositoryProvider).watchActiveVolume().first;
      if (volume == null || !mounted) return;
    }
    final dreams = ref.read(dreamsProvider(DreamStatusFilter.all)).value;
    final scenes = ref.read(scenesProvider(volume.id)).value;
    final created = await Navigator.of(context).push<bool>(
      v2Route(
        V2CaptureFlow(
          dreamNumber: (dreams?.length ?? 0) + 1,
          sceneNumber: (scenes?.length ?? 0) + 1,
        ),
      ),
    );
    if (created == true && mounted) setState(() => _tab = 0);
  }

  Future<void> _openReader({String? sceneId}) async {
    final volume = ref.read(activeVolumeProvider).value;
    if (volume == null) return;
    await Navigator.of(context).push(
      v2Route(
        V2ReaderScreen(
          volumeId: volume.id,
          initialSceneId: sceneId,
          onCapture: _openCapture,
        ),
      ),
    );
  }

  void _openSettings() {
    showV2ReadingSettingsWithExtras(context, extras: widget.extraSettings);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(outboxWorkerProvider);
    return Scaffold(
      backgroundColor: V2Color.paper,
      extendBody: true,
      body: V2Atmosphere(
        mood: _tab == 0 ? V2Mood.home : V2Mood.archive,
        child: IndexedStack(
          index: _tab,
          children: [
            V2HomeScreen(
              isActive: _tab == 0,
              onCapture: _openCapture,
              onRead: _openReader,
              onReadScene: (id) => _openReader(sceneId: id),
              onArchive: () => setState(() => _tab = 1),
              onSettings: _openSettings,
            ),
            V2ArchiveScreen(onCapture: _openCapture),
          ],
        ),
      ),
      bottomNavigationBar: V2FloatingNav(
        items: const [
          V2NavItem(icon: Icons.auto_stories_outlined, label: '원고'),
          V2NavItem(icon: Icons.inventory_2_outlined, label: '보관함'),
        ],
        selected: _tab,
        onSelect: (index) => setState(() => _tab = index),
        ctaLabel: '꿈 기록',
        onCta: _openCapture,
      ),
    );
  }
}

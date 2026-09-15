import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, this.initialNight = false});

  final bool initialNight;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late bool _night = widget.initialNight;
  bool _showOrigins = true;

  Color get _paper => _night ? MongColor.nightPaper : MongColor.paper;
  Color get _ink => _night ? MongColor.nightInk : MongColor.ink;
  Color get _meta => _night ? MongColor.nightMeta : MongColor.ink3;
  Color get _line => _night ? MongColor.ink2 : MongColor.line;

  void _setSystemStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _night ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _paper,
        systemNavigationBarIconBrightness: _night
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setSystemStyle());
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: MongColor.paper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _showSource(Passage passage) async {
    final repository = ref.read(repositoryProvider);
    final dreams = await repository.watchDreams(DreamStatusFilter.all).first;
    Dream? sourceDream;
    for (final dream in dreams) {
      if (dream.id == passage.sourceDreamId) {
        sourceDream = dream;
        break;
      }
    }
    if (!mounted) {
      return;
    }

    final isDream = passage.origin == PassageOrigin.dream;
    final isUser = passage.origin == PassageOrigin.user;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _night ? MongColor.nightShade : MongColor.paperPure,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 2,
                    color: _night ? MongColor.ink2 : MongColor.line,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  isDream ? '꿈에서' : (isUser ? '내가 씀' : '연결'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: _ink),
                ),
                const SizedBox(height: 7),
                Text(
                  _sourceDescription(passage, sourceDream),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: _meta),
                ),
                if (isDream && sourceDream != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    '원문',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: _meta),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sourceDream.rawText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.75,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QuietTextButton(label: '원문 전체 보기', onPressed: () {}),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final volumeAsync = ref.watch(activeVolumeProvider);
    return volumeAsync.when(
      loading: () => _readerMessage('원고를 불러오는 중'),
      error: (_, _) => _readerMessage('원고를 불러오지 못했어요.'),
      data: (volume) {
        if (volume == null) {
          return _readerMessage('아직 읽을 원고가 없어요.');
        }
        final scenesAsync = ref.watch(scenesProvider(volume.id));
        return scenesAsync.when(
          loading: () => _readerMessage('원고를 불러오는 중'),
          error: (_, _) => _readerMessage('원고를 불러오지 못했어요.'),
          data: (scenes) {
            if (scenes.isEmpty) {
              return _readerMessage('아직 읽을 장면이 없어요.');
            }
            final scene = scenes.last;
            final passagesAsync = ref.watch(passagesProvider(scene.id));
            return passagesAsync.when(
              loading: () => _readerMessage('문장을 불러오는 중'),
              error: (_, _) => _readerMessage('문장을 불러오지 못했어요.'),
              data: (passages) => _readerContent(
                volume: volume,
                scene: scene,
                sceneNumber: scenes.length,
                passages: passages,
              ),
            );
          },
        );
      },
    );
  }

  Widget _readerContent({
    required Volume volume,
    required Scene scene,
    required int sceneNumber,
    required List<Passage> passages,
  }) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, size: 20, color: _ink),
                    tooltip: '닫기',
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Row(
                      children: [
                        MetaText(
                          'VOL.${volume.volNo.toString().padLeft(2, '0')}',
                          color: _meta,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            volume.title ?? '이름 없는 원고',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: _meta),
                          ),
                        ),
                        MetaText(
                          'p.${(volume.progressMu * .7).round()}',
                          color: _meta,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: _night ? MongColor.nightShade : MongColor.paperPure,
                    surfaceTintColor: Colors.transparent,
                    icon: Icon(Icons.more_horiz, color: _ink),
                    onSelected: (value) {
                      if (value == 'origin') {
                        setState(() => _showOrigins = !_showOrigins);
                      }
                      if (value == 'night') {
                        setState(() => _night = !_night);
                        _setSystemStyle();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'origin',
                        child: Text(_showOrigins ? '출처 표시 끄기' : '출처 표시 켜기'),
                      ),
                      PopupMenuItem(
                        value: 'night',
                        child: Text(_night ? '낮의 종이로 읽기' : '밤의 종이로 읽기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: _line),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${scene.chapterNo ?? sceneNumber}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: _meta),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      scene.title ?? '제목 없는 장면',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: _ink),
                    ),
                    const SizedBox(height: 28),
                    for (var index = 0; index < passages.length; index++) ...[
                      if (index == passages.length - 1 &&
                          passages.length > 1) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '·',
                            style: TextStyle(fontSize: 22, color: _meta),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      ReaderPassage(
                        origin: passages[index].origin,
                        showOrigin: _showOrigins,
                        ink: _ink,
                        meta: _meta,
                        text: passages[index].text,
                        onTap: () => _showSource(passages[index]),
                      ),
                    ],
                    if (passages.isEmpty) MetaText('아직 문장이 없어요.', color: _meta),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readerMessage(String message) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(Icons.arrow_back, size: 20, color: _ink),
              tooltip: '닫기',
            ),
            Center(child: MetaText(message, color: _meta)),
          ],
        ),
      ),
    );
  }
}

class ReaderPassage extends StatelessWidget {
  const ReaderPassage({
    super.key,
    required this.origin,
    required this.showOrigin,
    required this.ink,
    required this.meta,
    required this.text,
    required this.onTap,
  });

  final PassageOrigin origin;
  final bool showOrigin;
  final Color ink;
  final Color meta;
  final String text;
  final VoidCallback onTap;

  String get _mark => switch (origin) {
    PassageOrigin.dream => '●',
    PassageOrigin.connection => '○',
    PassageOrigin.user => '│',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              origin == PassageOrigin.user
                  ? '내가 쓴 문장은 잠겨져 있어요.'
                  : '편집 모드를 준비했어요.',
            ),
            backgroundColor: MongColor.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: MongMotion.base,
              width: showOrigin ? 25 : 0,
              padding: const EdgeInsets.only(top: 5),
              child: showOrigin
                  ? Text(_mark, style: TextStyle(fontSize: 10, color: meta))
                  : null,
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sourceDescription(Passage passage, Dream? sourceDream) {
  return switch (passage.origin) {
    PassageOrigin.dream =>
      sourceDream == null
          ? '출처 꿈을 찾지 못했어요.'
          : '${sourceDream.dreamDate.month}월 ${sourceDream.dreamDate.day}일 기록한 꿈',
    PassageOrigin.connection => passage.cReason ?? '원고의 장면을 잇는 문장',
    PassageOrigin.user => '직접 쓴 문장은 원고에서 잠겨져요.',
  };
}

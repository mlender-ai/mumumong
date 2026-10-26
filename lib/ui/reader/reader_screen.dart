import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../../domain/source_highlight.dart';
import '../../core/log/app_log.dart';
import '../shared/content_state.dart';
import '../settings/appearance_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    this.initialNight,
    this.volumeId,
    this.initialSceneId,
    this.initialPassageId,
    this.onCapture,
  });

  final bool? initialNight;
  final String? volumeId;
  final String? initialSceneId;
  final String? initialPassageId;
  final VoidCallback? onCapture;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late bool? _nightOverride = widget.initialNight;
  bool get _night =>
      _nightOverride ??
      (context.isNight ||
          ref.read(uiPreferencesProvider).themeMode == ThemeMode.dark);
  bool get _showOrigins => ref.read(uiPreferencesProvider).showOrigins;
  final Set<String> _openedScenes = {};
  double _readerScale = 1;
  bool _reverting = false;
  bool _appNight = false;
  String? _selectedSceneId;
  late final MumumongRepository _repository;
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _passageKeys = {};
  Timer? _saveTimer;
  Future<void> _saveQueue = Future.value();
  ReaderPosition? _position;
  ReaderPosition? _restoreTarget;
  String? _renderedVolume;
  Scene? _renderedScene;
  List<Passage> _renderedPassages = [];
  String? _contentSignature;
  TextScaler? _textScaler;
  Size? _viewportSize;
  bool _restoreScheduled = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(repositoryProvider);
    _selectedSceneId = widget.initialSceneId;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setSystemStyle();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scale = MediaQuery.textScalerOf(context);
    final size = MediaQuery.sizeOf(context);
    if (_textScaler != null &&
        (_textScaler != scale || _viewportSize != size)) {
      _restoreTarget = _capturePosition() ?? _position;
      _contentSignature = null;
    }
    _textScaler = scale;
    _viewportSize = size;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _flushPosition();
  }

  double? _topOf(GlobalKey key) {
    final object = key.currentContext?.findRenderObject();
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (!_scroll.hasClients ||
        object is! RenderBox ||
        viewport is! RenderBox ||
        !object.hasSize ||
        !viewport.hasSize) {
      return null;
    }
    return object.localToGlobal(Offset.zero).dy -
        viewport.localToGlobal(Offset.zero).dy +
        _scroll.offset;
  }

  ReaderPosition? _capturePosition() {
    final scene = _renderedScene;
    if (_restoring || scene == null || !_scroll.hasClients) return _position;
    Passage? anchor;
    double fraction = 0;
    for (final passage in _renderedPassages) {
      final key = _passageKeys[passage.id];
      final top = key == null ? null : _topOf(key);
      final box = key?.currentContext?.findRenderObject();
      if (top == null || box is! RenderBox || !box.hasSize) continue;
      anchor = passage;
      fraction = ((_scroll.offset - top) / box.size.height).clamp(0.0, 1.0);
      if (top + box.size.height > _scroll.offset) break;
    }
    return ReaderPosition(
      volumeId: scene.volumeId,
      sceneId: scene.id,
      sceneOrderKey: scene.orderKey,
      passageId: anchor?.id,
      passageOrderKey: anchor?.orderKey,
      passageFraction: fraction,
      offset: _scroll.offset.clamp(0.0, double.infinity),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  void _onScroll() {
    if (_restoring || _restoreScheduled) return;
    _position = _capturePosition();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flushPosition);
  }

  void _flushPosition() {
    _saveTimer?.cancel();
    final position = _capturePosition();
    if (position == null || _restoreScheduled || _restoring) return;
    _position = position;
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _repository.saveReaderPosition(position);
      } on Object {
        // Owner changes/deletion invalidate an old screen's pending bookmark.
        AppLog.event('reader_position_failed', {'stage': 'save'});
      }
    });
  }

  void _prepareContent(
    Scene scene,
    List<Passage> passages,
    ReaderPosition? saved,
  ) {
    final switching =
        _renderedScene?.id != scene.id || _renderedVolume != scene.volumeId;
    if (switching) {
      _restoreTarget = _renderedScene == null && widget.initialSceneId == null
          ? saved
          : null;
      if (_restoreTarget?.sceneId != null &&
          _restoreTarget?.sceneId != scene.id) {
        _restoreTarget = null;
      }
      _position = null;
      _passageKeys.clear();
    } else if (_contentSignature != null) {
      _restoreTarget = _position;
    }
    final signature =
        '${scene.id}|$_showOrigins|$_readerScale|${passages.map((p) => '${p.id}:${p.orderKey}:${p.text.hashCode}').join('|')}';
    final changed = signature != _contentSignature;
    _renderedVolume = scene.volumeId;
    _renderedScene = scene;
    _renderedPassages = passages;
    for (final passage in passages) {
      _passageKeys.putIfAbsent(passage.id, GlobalKey.new);
    }
    _passageKeys.removeWhere((id, _) => !passages.any((p) => p.id == id));
    if (!changed || _restoreScheduled) return;
    _contentSignature = signature;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      if (!mounted || !_scroll.hasClients || _renderedScene?.id != scene.id) {
        return;
      }
      _restoring = true;
      if (passages.isNotEmpty &&
          passages.first.firstReadAt == null &&
          _openedScenes.add(scene.id)) {
        unawaited(
          _repository.markPassageRead(passages.first.id).catchError((Object _) {
            // Does not change prose; a later Reader entry may retry the marker.
          }),
        );
      }
      final target = _restoreTarget;
      Passage? passage = passages
          .where(
            (p) =>
                p.id ==
                (switching
                    ? widget.initialPassageId ?? target?.passageId
                    : target?.passageId),
          )
          .firstOrNull;
      if (passage == null &&
          target?.passageOrderKey != null &&
          passages.isNotEmpty) {
        passage =
            passages
                .where(
                  (p) => p.orderKey.compareTo(target!.passageOrderKey!) >= 0,
                )
                .firstOrNull ??
            passages.last;
      }
      var offset = target?.offset ?? 0.0;
      if (passage != null) {
        final key = _passageKeys[passage.id]!;
        final box = key.currentContext?.findRenderObject();
        final top = _topOf(key);
        if (top != null && box is RenderBox) {
          final sameAnchor = passage.id == target?.passageId;
          // A zero fraction means the beginning; preserve the title at offset 0.
          offset = target?.offset == 0 && sameAnchor
              ? 0
              : top +
                    box.size.height *
                        (sameAnchor ? target!.passageFraction : 0);
        }
      }
      _scroll.jumpTo(offset.clamp(0.0, _scroll.position.maxScrollExtent));
      _restoring = false;
      _restoreTarget = null;
      _position = _capturePosition();
    });
  }

  void _selectScene(String? id) {
    if (id == null || id == _renderedScene?.id) return;
    _flushPosition();
    setState(() => _selectedSceneId = id);
  }

  @override
  void dispose() {
    _flushPosition();
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _restoreSystemStyle();
    super.dispose();
  }

  Future<void> _edit(Passage passage) async {
    final controller = TextEditingController(text: passage.text);
    var saving = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) {
          Future<void> save({bool revert = false}) async {
            if (saving || (!revert && controller.text.trim().isEmpty)) return;
            update(() {
              saving = true;
              error = null;
            });
            try {
              final repository = ref.read(repositoryProvider);
              if (revert) {
                await repository.revertPassage(passage.id);
              } else {
                await repository.editPassage(
                  passage.id,
                  controller.text.trim(),
                );
              }
              AppLog.event('passage_edited', {
                'passage_id': passage.id,
                'mode': revert ? 'revert' : 'edit',
              });
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            } on Object {
              if (context.mounted) {
                update(() {
                  saving = false;
                  error = '저장하지 못했어요. 입력한 문장은 그대로 남아 있어요.';
                });
              }
            }
          }

          return PopScope(
            canPop: !saving,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 문장으로 고치기',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: _ink),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '저장한 문장은 AI가 바꾸지 않아요.',
                      style: TextStyle(color: _meta),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 12,
                      enabled: !saving,
                      style: TextStyle(color: _ink),
                      decoration: const InputDecoration(labelText: '문장'),
                    ),
                    if (error != null)
                      Text(error!, style: TextStyle(color: _ink)),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        if (passage.originalText != null)
                          TextButton(
                            onPressed: saving ? null : () => save(revert: true),
                            child: const Text('원래 문장으로'),
                          ),
                        TextButton(
                          onPressed: saving ? null : save,
                          child: Text(saving ? '저장 중' : '저장'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    // The closing route still owns the field during its exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
  }

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

  void _restoreSystemStyle() {
    final night = _appNight;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: night ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: night
            ? const Color(0xFF050C18)
            : MongColor.paper,
        systemNavigationBarIconBrightness: night
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  Future<void> _showSource(Passage passage) async {
    try {
      await _loadSource(passage);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출처를 불러오지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<void> _loadSource(Passage passage) async {
    final repository = ref.read(repositoryProvider);
    final dreams = await repository.watchDreams(DreamStatusFilter.all).first;
    final elements = passage.sourceDreamId == null
        ? <DreamElement>[]
        : await repository.watchDreamElements(passage.sourceDreamId!).first;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MongSheetHandle(
                  color: _night ? MongColor.ink2 : MongColor.line,
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
                  SelectableText.rich(
                    _sourceSpan(
                      sourceDream.rawText,
                      elements.where(
                        (element) =>
                            passage.sourceElementIds.contains(element.id),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.75,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '하늘색은 이 문장이 가져온 기억이에요.',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: _meta),
                  ),
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
    final preferences = ref.watch(uiPreferencesProvider);
    _appNight = preferences.themeMode == ThemeMode.dark || context.isNight;
    _readerScale = preferences.readerScale;
    final volumeAsync = ref.watch(activeVolumeProvider);
    return volumeAsync.when(
      loading: () => _readerMessage('원고를 불러오는 중'),
      error: (_, _) => _readerMessage(
        '원고를 불러오지 못했어요.',
        action: '다시 불러오기',
        onAction: () => ref.invalidate(activeVolumeProvider),
      ),
      data: (volume) {
        if (volume == null) {
          return _emptyReader('아직 읽을 원고가 없어요.');
        }
        if (widget.volumeId != null && widget.volumeId != volume.id) {
          return _unavailableReader();
        }
        final bookmark = ref.watch(readerPositionProvider(volume.id));
        if (bookmark.isLoading) return _readerMessage('읽던 위치를 불러오는 중');
        if (bookmark.hasError) {
          return _readerMessage(
            '읽던 위치를 불러오지 못했어요.',
            action: '다시 불러오기',
            onAction: () => ref.invalidate(readerPositionProvider(volume.id)),
          );
        }
        final scenesAsync = ref.watch(scenesProvider(volume.id));
        return scenesAsync.when(
          loading: () => _readerMessage('원고를 불러오는 중'),
          error: (_, _) => _readerMessage(
            '원고를 불러오지 못했어요.',
            action: '다시 불러오기',
            onAction: () => ref.invalidate(scenesProvider(volume.id)),
          ),
          data: (loadedScenes) {
            final scenes = loadedScenes
                .where((s) => s.volumeId == volume.id)
                .toList();
            if (scenes.isEmpty) {
              return widget.initialSceneId != null
                  ? _unavailableReader()
                  : _emptyReader('아직 읽을 장면이 없어요.');
            }
            final saved = bookmark.value;
            var scene = scenes
                .where((s) => s.id == _selectedSceneId)
                .firstOrNull;
            if (_selectedSceneId != null && scene == null) {
              return _unavailableReader();
            }
            scene ??= scenes.where((s) => s.id == saved?.sceneId).firstOrNull;
            if (scene == null && saved?.sceneOrderKey != null) {
              scene =
                  scenes
                      .where(
                        (s) => s.orderKey.compareTo(saved!.sceneOrderKey!) >= 0,
                      )
                      .firstOrNull ??
                  scenes.last;
            }
            scene ??= scenes.last;
            _selectedSceneId = scene.id;
            final passagesAsync = ref.watch(passagesProvider(scene.id));
            return passagesAsync.when(
              loading: () => _readerMessage('문장을 불러오는 중'),
              error: (_, _) => _readerMessage(
                '문장을 불러오지 못했어요.',
                action: '다시 불러오기',
                onAction: () => ref.invalidate(passagesProvider(scene!.id)),
              ),
              data: (passages) {
                _prepareContent(scene!, passages, saved);
                return _readerContent(
                  volume: volume,
                  scene: scene,
                  sceneNumber: scenes.indexOf(scene) + 1,
                  passages: passages,
                  scenes: scenes,
                );
              },
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
    required List<Scene> scenes,
  }) {
    return Scaffold(
      backgroundColor: _paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SafeArea(
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
                        color: _night
                            ? MongColor.nightShade
                            : MongColor.paperPure,
                        surfaceTintColor: Colors.transparent,
                        icon: Icon(Icons.more_horiz, color: _ink),
                        onSelected: (value) {
                          if (value == 'origin') {
                            _saveAppearance(origins: !_showOrigins);
                          }
                          if (value == 'night') {
                            _saveAppearance(night: !_night);
                          }
                          if (value == 'appearance') {
                            Navigator.of(context)
                                .push(quietPageRoute(const AppearanceScreen()))
                                .then((_) {
                                  if (mounted) {
                                    setState(() => _nightOverride = null);
                                  }
                                });
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
                          const PopupMenuItem(
                            value: 'appearance',
                            child: Text('화면과 글자 크기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: _line),
                const OfflineNotice(),
                if (scenes.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DropdownButton<String>(
                      value: scene.id,
                      isExpanded: true,
                      dropdownColor: _paper,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _meta),
                      items: [
                        for (var i = 0; i < scenes.length; i++)
                          DropdownMenuItem(
                            value: scenes[i].id,
                            child: Text(
                              '${i + 1}. ${scenes[i].title ?? '제목 없는 장면'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _selectScene,
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    key: _viewportKey,
                    controller: _scroll,
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
                        for (
                          var index = 0;
                          index < passages.length;
                          index++
                        ) ...[
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
                            key: _passageKeys[passages[index].id],
                            origin: passages[index].origin,
                            showOrigin: _showOrigins,
                            ink: _ink,
                            meta: _meta,
                            text: passages[index].text,
                            fontScale: _readerScale,
                            onTap: () => _showSource(passages[index]),
                            onLongPress: () => _edit(passages[index]),
                            onMenu: (value) => value == 'source'
                                ? _showSource(passages[index])
                                : value == 'revert'
                                ? _confirmRevert(passages[index])
                                : _edit(passages[index]),
                            canRevert: passages[index].originalText != null,
                          ),
                        ],
                        if (passages.isEmpty) ...[
                          MetaText(
                            '아직 문장이 없어요. 기록은 그대로 보관되어 있어요.',
                            color: _meta,
                          ),
                          const SizedBox(height: 24),
                          EditorialButton(
                            label: '다시 불러오기',
                            onPressed: () =>
                                ref.invalidate(passagesProvider(scene.id)),
                          ),
                        ],
                        if (scenes.length == 1 && passages.isNotEmpty)
                          _firstSceneAfterword(passages),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _firstSceneAfterword(List<Passage> passages) {
    final source = passages
        .where(
          (p) => p.origin == PassageOrigin.dream && p.sourceDreamId != null,
        )
        .firstOrNull;
    return Padding(
      key: const Key('first-scene-afterword'),
      padding: const EdgeInsets.only(top: MongSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: _line),
          const SizedBox(height: MongSpace.lg),
          Text(
            '첫 장면은 여기에 남아 있어요.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: _ink),
          ),
          const SizedBox(height: 12),
          Text(
            '지금은 이 장면만 간직해도 괜찮아요.\n다음 꿈이 떠오르면 내 원고에서 다시 기록해 보세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _night ? MongColor.nightMeta : MongColor.ink2,
            ),
          ),
          const SizedBox(height: MongSpace.xl),
          MongActionGroup(
            secondaryColor: _night ? MongColor.nightMeta : MongColor.ink2,
            primary: GlassActionButton(
              label: '읽기 마치기',
              lightContent: _night,
              onPressed: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).pop()
                  : null,
            ),
            secondary: [
              if (source != null)
                TextButton(
                  onPressed: () => _showSource(source),
                  child: const Text('꿈 원문 다시 보기'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveAppearance({bool? night, bool? origins}) async {
    final ok = await ref
        .read(uiPreferencesProvider)
        .save(
          theme: night == null
              ? null
              : night
              ? ThemeMode.dark
              : ThemeMode.light,
          origins: origins,
        );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('읽기 설정을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    } else if (night != null) {
      setState(() => _nightOverride = night);
      _setSystemStyle();
    }
  }

  Future<void> _confirmRevert(Passage passage) async {
    if (_reverting || passage.originalText == null) return;
    _reverting = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('원래 문장으로 돌아갈까요?'),
          content: SingleChildScrollView(child: Text(passage.originalText!)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('원래 문장으로'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _repository.revertPassage(passage.id);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('되돌리지 못했어요. 현재 문장은 그대로 남아 있어요.')),
        );
      }
    } finally {
      _reverting = false;
    }
  }

  Widget _emptyReader(String message) => _readerMessage(
    message,
    action: widget.onCapture == null ? '돌아가기' : '첫 꿈 기록하기',
    onAction: () {
      Navigator.maybePop(context);
      widget.onCapture?.call();
    },
  );

  Widget _unavailableReader() => _readerMessage(
    '이 장면은 원고에서 찾을 수 없어요. 삭제되었거나 다른 원고의 장면일 수 있어요.',
    action: '돌아가기',
    onAction: () => Navigator.maybePop(context),
  );

  Widget _readerMessage(
    String message, {
    String? action,
    VoidCallback? onAction,
  }) {
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _meta),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 24),
                      EditorialButton(label: action, onPressed: onAction),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _sourceSpan(String text, Iterable<DreamElement> elements) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in sourceHighlights(text, elements)) {
      spans.add(TextSpan(text: text.substring(cursor, range.$1)));
      spans.add(
        TextSpan(
          text: text.substring(range.$1, range.$2),
          style: const TextStyle(
            backgroundColor: MongColor.sky100,
            color: MongColor.ink,
          ),
        ),
      );
      cursor = range.$2;
    }
    spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(children: spans);
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
    this.onLongPress,
    this.onMenu,
    this.canRevert = false,
    this.fontScale = 1,
  });

  final PassageOrigin origin;
  final bool showOrigin;
  final Color ink;
  final Color meta;
  final String text;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onMenu;
  final bool canRevert;
  final double fontScale;

  String get _mark => switch (origin) {
    PassageOrigin.dream => '●',
    PassageOrigin.connection => '○',
    PassageOrigin.user => '│',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ink,
                  fontSize: 18 * fontScale,
                ),
              ),
            ),
            if (onMenu != null)
              SizedBox(
                width: 44,
                child: PopupMenuButton<String>(
                  tooltip: '문단 메뉴',
                  icon: Icon(Icons.more_horiz, color: meta, size: 18),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'source', child: Text('출처 보기')),
                    const PopupMenuItem(value: 'edit', child: Text('문장 수정')),
                    if (canRevert)
                      const PopupMenuItem(
                        value: 'revert',
                        child: Text('원래 문장으로'),
                      ),
                  ],
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

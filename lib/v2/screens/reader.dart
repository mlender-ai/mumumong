// V2 Story Reader (brief §7.6): literary readability and digital-book
// quality first. Paper only, a measured serif column, quiet origin marks in
// the margin, one passage sheet for source and editing, and floating reader
// navigation. Position, read markers and edits use the same repository
// calls as V1.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log/app_log.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../../domain/source_highlight.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/navigation.dart';
import '../components/offline.dart';
import '../design/dot_matrix.dart';
import '../design/press.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'reading_settings.dart';

class V2ReaderScreen extends ConsumerStatefulWidget {
  const V2ReaderScreen({
    super.key,
    this.volumeId,
    this.initialSceneId,
    this.initialPassageId,
    this.onCapture,
  });

  final String? volumeId;
  final String? initialSceneId;
  final String? initialPassageId;
  final VoidCallback? onCapture;

  @override
  ConsumerState<V2ReaderScreen> createState() => _V2ReaderScreenState();
}

class _V2ReaderScreenState extends ConsumerState<V2ReaderScreen>
    with WidgetsBindingObserver {
  final Set<String> _openedScenes = {};
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
  bool _reverting = false;
  bool _scrolled = false;
  double _readerScale = 1;
  bool _showOrigins = false;
  bool _night = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(repositoryProvider);
    _selectedSceneId = widget.initialSceneId;
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
    _flushPosition();
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  // ------------------------------------------------- position (from V1)

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
    final scrolled = _scroll.hasClients && _scroll.offset > 12;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
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
            // Does not change prose; a later Reader entry may retry.
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

  // ------------------------------------------------- colors

  Color get _paper => _night ? V2Color.nightPaper : V2Color.paper;
  Color get _ink => _night ? V2Color.nightInk : V2Color.ink;
  Color get _meta => _night ? V2Color.nightMeta : V2Color.ink3;

  // ------------------------------------------------- passage sheet

  Future<void> _openPassage(Passage passage, int index) async {
    List<Dream> dreams;
    List<DreamElement> elements;
    try {
      dreams = await _repository.watchDreams(DreamStatusFilter.all).first;
      elements = passage.sourceDreamId == null
          ? <DreamElement>[]
          : await _repository.watchDreamElements(passage.sourceDreamId!).first;
    } on Object {
      if (mounted) showV2Toast(context, '출처를 불러오지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (!mounted) return;
    final source = dreams
        .where((d) => d.id == passage.sourceDreamId)
        .firstOrNull;
    final isDream = passage.origin == PassageOrigin.dream;
    final isUser = passage.origin == PassageOrigin.user;
    final action = await showV2Sheet<String>(
      context,
      night: _night,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _OriginMark(origin: passage.origin, night: _night),
                const SizedBox(width: 10),
                Text(
                  isDream ? '꿈에서 온 문장' : (isUser ? '내가 쓴 문장' : '장면을 잇는 문장'),
                  style: V2Type.headline.copyWith(color: _ink),
                ),
              ],
            ),
            const SizedBox(height: V2Space.xxs),
            V2Meta(_sourceDescription(passage, source), color: _meta),
            if (isDream && source != null) ...[
              const SizedBox(height: V2Space.lg),
              V2Meta('원문', color: _meta),
              const SizedBox(height: V2Space.xs),
              SelectableText.rich(
                _sourceSpan(
                  source.rawText,
                  elements.where(
                    (e) => passage.sourceElementIds.contains(e.id),
                  ),
                ),
                style: V2Type.reading.copyWith(
                  fontSize: 16,
                  height: 1.75,
                  color: _ink,
                ),
              ),
              const SizedBox(height: V2Space.sm),
              V2Meta('하늘색은 이 문장이 가져온 기억이에요.', color: _meta),
            ],
            const SizedBox(height: V2Space.lg),
            V2Button.secondary(
              label: '내 문장으로 고치기',
              icon: Icons.edit_outlined,
              expand: true,
              onPressed: () => Navigator.pop(sheetContext, 'edit'),
            ),
            if (passage.originalText != null) ...[
              const SizedBox(height: V2Space.xs),
              V2Button.glass(
                label: '원래 문장으로',
                expand: true,
                onPressed: () => Navigator.pop(sheetContext, 'revert'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _edit(passage);
    if (action == 'revert') await _confirmRevert(passage);
  }

  Future<void> _edit(Passage passage) async {
    final controller = TextEditingController(text: passage.text);
    var saving = false;
    String? error;
    await showV2Sheet<void>(
      context,
      night: _night,
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('내 문장으로 고치기', style: V2Type.title.copyWith(color: _ink)),
                  const SizedBox(height: V2Space.xs),
                  V2Meta('저장한 문장은 AI가 바꾸지 않아요.', color: _meta),
                  const SizedBox(height: V2Space.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _night ? const Color(0xFF2E2C27) : Colors.white,
                      borderRadius: BorderRadius.circular(V2Radius.field - 6),
                      border: Border.all(color: V2Color.sky400, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(V2Space.md),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 12,
                        enabled: !saving,
                        cursorColor: V2Color.sky600,
                        style: V2Type.reading.copyWith(
                          fontSize: 17,
                          color: _ink,
                        ),
                        decoration: const InputDecoration.collapsed(
                          hintText: '문장',
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: V2Space.xs),
                    Text(
                      error!,
                      style: V2Type.bodySmall.copyWith(color: V2Color.alert),
                    ),
                  ],
                  const SizedBox(height: V2Space.md),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      V2TextAction(
                        label: '취소',
                        color: _meta,
                        onPressed: saving ? null : () => Navigator.pop(context),
                      ),
                      if (passage.originalText != null)
                        V2Button.secondary(
                          label: '원래 문장으로',
                          size: V2ButtonSize.compact,
                          onPressed: saving ? null : () => save(revert: true),
                        ),
                      V2Button(
                        label: '저장',
                        size: V2ButtonSize.compact,
                        loading: saving,
                        loadingLabel: '저장 중',
                        onPressed: saving ? null : save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
  }

  Future<void> _confirmRevert(Passage passage) async {
    if (_reverting || passage.originalText == null) return;
    _reverting = true;
    try {
      final confirmed = await showV2Dialog<bool>(
        context,
        title: '원래 문장으로 돌아갈까요?',
        body: passage.originalText!,
        actions: (dialogContext) => [
          V2Button.secondary(
            label: '취소',
            size: V2ButtonSize.compact,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          V2Button(
            label: '원래 문장으로',
            size: V2ButtonSize.compact,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      );
      if (confirmed == true && mounted) {
        await _repository.revertPassage(passage.id);
      }
    } on Object {
      if (mounted) showV2Toast(context, '되돌리지 못했어요. 현재 문장은 그대로 남아 있어요.');
    } finally {
      _reverting = false;
    }
  }

  Future<void> _pickScene(List<Scene> scenes, String currentId) async {
    final picked = await showV2Sheet<String>(
      context,
      night: _night,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .62,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('장면 고르기', style: V2Type.title.copyWith(color: _ink)),
            const SizedBox(height: V2Space.sm),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: scenes.length,
                itemBuilder: (context, i) => _SceneRow(
                  number: i + 1,
                  title: scenes[i].title ?? '제목 없는 장면',
                  current: scenes[i].id == currentId,
                  night: _night,
                  onTap: () => Navigator.pop(sheetContext, scenes[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && picked != currentId) _selectScene(picked);
  }

  // ------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(uiPreferencesProvider);
    _night = preferences.themeMode == ThemeMode.dark;
    _readerScale = preferences.readerScale;
    _showOrigins = preferences.showOrigins;
    final volumeAsync = ref.watch(activeVolumeProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: volumeAsync.when(
        loading: () => _message('원고를 펼치는 중'),
        error: (_, _) => _message(
          '원고를 불러오지 못했어요.',
          action: '다시 불러오기',
          onAction: () => ref.invalidate(activeVolumeProvider),
        ),
        data: (volume) {
          if (volume == null) return _empty('아직 읽을 원고가 없어요.');
          if (widget.volumeId != null && widget.volumeId != volume.id) {
            return _unavailable();
          }
          final bookmark = ref.watch(readerPositionProvider(volume.id));
          if (bookmark.isLoading) return _message('읽던 위치를 찾는 중');
          if (bookmark.hasError) {
            return _message(
              '읽던 위치를 불러오지 못했어요.',
              action: '다시 불러오기',
              onAction: () => ref.invalidate(readerPositionProvider(volume.id)),
            );
          }
          final scenesAsync = ref.watch(scenesProvider(volume.id));
          return scenesAsync.when(
            loading: () => _message('원고를 펼치는 중'),
            error: (_, _) => _message(
              '원고를 불러오지 못했어요.',
              action: '다시 불러오기',
              onAction: () => ref.invalidate(scenesProvider(volume.id)),
            ),
            data: (loaded) {
              final scenes = loaded
                  .where((s) => s.volumeId == volume.id)
                  .toList();
              if (scenes.isEmpty) {
                return widget.initialSceneId != null
                    ? _unavailable()
                    : _empty('아직 읽을 장면이 없어요.');
              }
              final saved = bookmark.value;
              var scene = scenes
                  .where((s) => s.id == _selectedSceneId)
                  .firstOrNull;
              if (_selectedSceneId != null && scene == null) {
                return _unavailable();
              }
              scene ??= scenes.where((s) => s.id == saved?.sceneId).firstOrNull;
              if (scene == null && saved?.sceneOrderKey != null) {
                scene =
                    scenes
                        .where(
                          (s) =>
                              s.orderKey.compareTo(saved!.sceneOrderKey!) >= 0,
                        )
                        .firstOrNull ??
                    scenes.last;
              }
              scene ??= scenes.last;
              _selectedSceneId = scene.id;
              final passagesAsync = ref.watch(passagesProvider(scene.id));
              return passagesAsync.when(
                loading: () => _message('문장을 펼치는 중'),
                error: (_, _) => _message(
                  '문장을 불러오지 못했어요.',
                  action: '다시 불러오기',
                  onAction: () => ref.invalidate(passagesProvider(scene!.id)),
                ),
                data: (passages) {
                  _prepareContent(scene!, passages, saved);
                  return _content(volume, scene, scenes, passages);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _content(
    Volume volume,
    Scene scene,
    List<Scene> scenes,
    List<Passage> passages,
  ) {
    final index = scenes.indexWhere((s) => s.id == scene.id);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final chapter = scene.chapterNo ?? index + 1;
    return Scaffold(
      backgroundColor: _paper,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: V2Space.readingMeasure + 80,
                ),
                child: SingleChildScrollView(
                  key: _viewportKey,
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    V2Space.gutter + 4,
                    top + 84,
                    V2Space.gutter + 4,
                    bottom + 132,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      V2OfflineNotice(night: _night),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          V2DotMatrix(
                            chapter.toString().padLeft(2, '0'),
                            pitch: 4.4,
                            color: _night ? V2Color.nightDot : V2Color.sky600,
                            semanticsLabel: '$chapter장',
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: V2Meta(
                              '장면 ${index + 1} / ${scenes.length}',
                              color: _meta,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: V2Space.md),
                      Semantics(
                        header: true,
                        child: Text(
                          scene.title ?? '제목 없는 장면',
                          style: V2Type.display.copyWith(
                            color: _ink,
                            fontSize: 28 * math.min(_readerScale, 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: V2Space.xl),
                      for (var i = 0; i < passages.length; i++) ...[
                        if (i == passages.length - 1 && passages.length > 1)
                          _SectionBreak(color: _meta),
                        _Passage(
                          key: _passageKeys[passages[i].id],
                          passage: passages[i],
                          index: i,
                          showOrigin: _showOrigins,
                          scale: _readerScale,
                          ink: _ink,
                          night: _night,
                          onTap: () => _openPassage(passages[i], i),
                        ),
                      ],
                      if (passages.isEmpty) ...[
                        V2Meta('아직 문장이 없어요. 기록은 그대로 보관되어 있어요.', color: _meta),
                        const SizedBox(height: V2Space.lg),
                        V2Button(
                          label: '다시 불러오기',
                          onPressed: () =>
                              ref.invalidate(passagesProvider(scene.id)),
                        ),
                      ],
                      if (scenes.length == 1 && passages.isNotEmpty)
                        _afterword(passages),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: V2ContextHeader(
              elevated: _scrolled,
              night: _night,
              leading: V2IconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: '닫기',
                variant: _night
                    ? V2IconButtonVariant.plain
                    : V2IconButtonVariant.glass,
                color: _ink,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${v2Volume(volume)}  ·  ${volume.title ?? '이름 없는 원고'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: V2Type.meta.copyWith(color: _meta),
              ),
              trailing: V2IconButton(
                icon: Icons.text_fields_rounded,
                semanticLabel: '읽기 설정',
                variant: _night
                    ? V2IconButtonVariant.plain
                    : V2IconButtonVariant.glass,
                color: _ink,
                onPressed: () => showV2ReadingSettings(context, night: _night),
              ),
            ),
          ),
          if (scenes.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: V2ReaderNav(
                index: index,
                count: scenes.length,
                night: _night,
                onPrevious: index > 0
                    ? () => _selectScene(scenes[index - 1].id)
                    : null,
                onNext: index < scenes.length - 1
                    ? () => _selectScene(scenes[index + 1].id)
                    : null,
                onPick: () => _pickScene(scenes, scene.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _afterword(List<Passage> passages) {
    final source = passages
        .where(
          (p) => p.origin == PassageOrigin.dream && p.sourceDreamId != null,
        )
        .firstOrNull;
    return Padding(
      key: const Key('v2-first-scene-afterword'),
      padding: const EdgeInsets.only(top: V2Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionBreak(color: _meta),
          Text(
            '첫 장면은 여기에 남아 있어요.',
            style: V2Type.headline.copyWith(color: _ink),
          ),
          const SizedBox(height: V2Space.xs),
          Text(
            '지금은 이 장면만 간직해도 괜찮아요.\n다음 꿈이 떠오르면 내 원고에서 다시 기록해 보세요.',
            style: V2Type.bodySmall.copyWith(color: _meta),
          ),
          const SizedBox(height: V2Space.lg),
          V2Button(
            label: '읽기 마치기',
            expand: true,
            onPressed: Navigator.of(context).canPop()
                ? () => Navigator.of(context).pop()
                : null,
          ),
          if (source != null)
            Center(
              child: V2TextAction(
                label: '꿈 원문 다시 보기',
                color: _meta,
                onPressed: () => _openPassage(source, 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(String message) => _message(
    message,
    action: widget.onCapture == null ? '돌아가기' : '첫 꿈 기록하기',
    onAction: () {
      Navigator.maybePop(context);
      widget.onCapture?.call();
    },
  );

  Widget _unavailable() => _message(
    '이 장면은 원고에서 찾을 수 없어요. 삭제되었거나 다른 원고의 장면일 수 있어요.',
    action: '돌아가기',
    onAction: () => Navigator.maybePop(context),
  );

  Widget _message(String message, {String? action, VoidCallback? onAction}) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: V2IconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: '닫기',
                variant: V2IconButtonVariant.plain,
                color: _ink,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(V2Space.gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: V2Type.body.copyWith(color: _meta),
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: V2Space.lg),
                      V2Button(label: action, onPressed: onAction),
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
          style: TextStyle(
            backgroundColor: _night ? const Color(0xFF2B3A4A) : V2Color.sky100,
            color: _ink,
          ),
        ),
      );
      cursor = range.$2;
    }
    spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(children: spans);
  }
}

class _Passage extends StatelessWidget {
  const _Passage({
    super.key,
    required this.passage,
    required this.index,
    required this.showOrigin,
    required this.scale,
    required this.ink,
    required this.night,
    required this.onTap,
  });

  final Passage passage;
  final int index;
  final bool showOrigin;
  final double scale;
  final Color ink;
  final bool night;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = V2Type.reading.copyWith(
      color: ink,
      fontSize: V2Type.reading.fontSize! * scale,
    );
    return V2Pressable(
      onPressed: onTap,
      haptic: V2Haptic.selection,
      semanticLabel: null,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.only(bottom: V2Space.lg),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -10,
              right: -10,
              top: -6,
              bottom: -6,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (night ? Colors.white : V2Color.sky500).withValues(
                      alpha: .07 * state.sink + .03 * state.hover,
                    ),
                    borderRadius: BorderRadius.circular(V2Radius.small),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: V2Motion.of(context, V2Motion.base),
                  width: showOrigin ? 20 : 0,
                  padding: EdgeInsets.only(top: style.fontSize! * .72),
                  child: showOrigin
                      ? _OriginMark(origin: passage.origin, night: night)
                      : null,
                ),
                Expanded(child: Text(v2KeepAll(passage.text), style: style)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginMark extends StatelessWidget {
  const _OriginMark({required this.origin, required this.night});

  final PassageOrigin origin;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final color = night ? V2Color.nightDot : V2Color.sky600;
    return Semantics(
      label: switch (origin) {
        PassageOrigin.dream => '꿈에서 온 문장',
        PassageOrigin.connection => '장면을 잇는 문장',
        PassageOrigin.user => '내가 쓴 문장',
      },
      child: Align(
        alignment: Alignment.topLeft,
        child: switch (origin) {
          PassageOrigin.dream => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          PassageOrigin.connection => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.3),
            ),
          ),
          PassageOrigin.user => Container(
            width: 2,
            height: 16,
            color: night ? V2Color.nightInk : V2Color.ink,
          ),
        },
      ),
    );
  }
}

class _SectionBreak extends StatelessWidget {
  const _SectionBreak({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: V2Space.xl, top: V2Space.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .7),
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
  );
}

class _SceneRow extends StatelessWidget {
  const _SceneRow({
    required this.number,
    required this.title,
    required this.current,
    required this.night,
    required this.onTap,
  });

  final int number;
  final String title;
  final bool current;
  final bool night;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = night ? V2Color.nightInk : V2Color.ink;
    return V2Pressable(
      onPressed: onTap,
      selected: current,
      semanticLabel: '$number. $title${current ? ', 지금 읽는 장면' : ''}',
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: night ? V2Color.nightLine : V2Color.hairline,
            ),
          ),
          color: ink.withValues(alpha: .04 * state.sink),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: V2DotMatrix(
                number.toString().padLeft(2, '0'),
                pitch: 1.8,
                color: current
                    ? V2Color.sky600
                    : (night ? V2Color.nightMeta : V2Color.ink3),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: V2Type.body.copyWith(color: ink, fontSize: 16),
              ),
            ),
            if (current)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: V2Color.sky500,
                  shape: BoxShape.circle,
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
    PassageOrigin.user => '직접 쓴 문장은 원고에서 잠겨요.',
  };
}

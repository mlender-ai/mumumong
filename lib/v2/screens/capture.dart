// V2 Dream Capture → AI Processing → Story Reveal (brief §7.3–7.5).
//
// The state machine, repository calls, engine enqueue/retry, idempotency,
// recovery and presentation receipts are ported unchanged from V1
// `CaptureFlow`; only presentation is new. One MemorySwarm carries the dream
// through every step: loose dots that answer typing and voice, one memory
// fragment on save, element groups, links and sentence rows that follow the
// real job stage, and rows that dissolve into the real text on reveal.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/log/app_log.dart';
import '../../data/engine/engine_client.dart';
import '../../data/speech/speech_input.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../../ui/capture/draft_autosave.dart';
import 'settings.dart' show V2VoicePage;
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../components/orb.dart';
import '../components/progress.dart';
import '../design/atmosphere.dart';
import '../design/dot_matrix.dart';
import '../design/memory_swarm.dart';
import '../design/press.dart';
import '../design/surface.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'reader.dart';
import 'v2_providers.dart';

enum V2CaptureStep { capture, saved, recall, processing, reveal, archived }

/// Stage copy shown in serif; the engine's own label sits beneath it.
const v2StageTitles = [
  '꿈을 읽고 있어요',
  '이어질 곳을 찾고 있어요',
  '장면을 쓰고 있어요',
  '문장을 확인하고 있어요',
];

class V2CaptureFlow extends ConsumerStatefulWidget {
  const V2CaptureFlow({
    super.key,
    required this.dreamNumber,
    required this.sceneNumber,
    this.savedDream,
  });

  final int dreamNumber;
  final int sceneNumber;
  final Dream? savedDream;

  @override
  ConsumerState<V2CaptureFlow> createState() => _V2CaptureFlowState();
}

class _V2CaptureFlowState extends ConsumerState<V2CaptureFlow>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _editorFocus = FocusNode(debugLabel: 'v2-dream-capture-editor');
  late final MemorySwarm _swarm = MemorySwarm(vsync: this);
  final _voiceLevel = ValueNotifier<double>(0);
  Timer? _voiceDecay;
  String _lastDraftText = '';
  V2CaptureStep _step = V2CaptureStep.capture;
  bool _recording = false;
  int _speechSession = 0;
  late final SpeechInput _speech;
  StreamSubscription<SpeechUpdate>? _speechSubscription;
  String _voicePrefix = '';
  bool _voiceHasText = false;
  String? _voiceNotice;
  bool _processingFailed = false;
  String? _processingFailureCode;
  ProviderSubscription<AsyncValue<JobProgress?>>? _jobSubscription;
  bool _connectionInterrupted = false;
  bool _submittingGeneration = false;
  bool _retryRequestPending = false;
  bool _submissionUncertain = false;
  int _processingStage = 0;
  String? _stageLabel;
  int _attempt = 1;
  final Map<String, String> _answers = {};
  String? _linkChoice;
  LinkDecision? _revealDecision;
  bool _savingLink = false;
  String? _dreamId;
  Scene? _revealScene;
  List<Passage> _revealPassages = const [];
  int _revealDeltaPercent = 0;
  bool _jobDone = false;
  bool _usedVoice = false;
  bool _revealScheduled = false;
  bool _revealClaimScheduled = false;
  bool _revealClaimBusy = false;
  bool _freshReveal = false;
  bool _freshGrowth = false;
  String? _revealGrowthEventId;
  bool _presentationError = false;
  bool _archiveScheduled = false;
  String? _engineIdempotencyKey;
  late final DraftAutosave _autosave;
  DreamDraft? _draft;
  bool _draftReady = false;
  bool _draftLoadFailed = false;
  bool _draftDiscardFailed = false;
  bool _submitting = false;
  bool _savingRecall = false;
  _SwarmLayout? _layout;
  bool _swarmSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _editorFocus.addListener(_onEditorFocus);
    _autosave = DraftAutosave(ref.read(repositoryProvider));
    _controller.addListener(_onEditorValueChanged);
    _speech = ref.read(speechInputProvider);
    _swarm.addListener(_mirrorLevel);
    final saved = widget.savedDream;
    if (saved != null) {
      _dreamId = saved.id;
      _answers.addAll(saved.recallAnswers);
      _step = saved.status == DreamStatus.queued
          ? V2CaptureStep.saved
          : V2CaptureStep.processing;
      _processingFailed = saved.status == DreamStatus.failed;
      _processingFailureCode = _processingFailed ? 'job_failed' : null;
      _engineIdempotencyKey = saved.id;
      _draftReady = true;
      _swarm.seed(MemorySwarm.dotsForText(saved.rawText.length));
      if (_step == V2CaptureStep.processing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _observeProcessing();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosave.dispose();
    unawaited(_speechSubscription?.cancel());
    unawaited(_speech.stop());
    _jobSubscription?.close();
    _voiceDecay?.cancel();
    _swarm.removeListener(_mirrorLevel);
    _swarm.dispose();
    _voiceLevel.dispose();
    _controller.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  void _mirrorLevel() {
    if (_voiceLevel.value != _swarm.level) _voiceLevel.value = _swarm.level;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopRecording();
    }
    if (state != AppLifecycleState.resumed) unawaited(_autosave.flush());
  }

  // ---------------------------------------------------------------- swarm

  /// Re-forms the swarm from the current state. Only state changes and
  /// layout changes (keyboard, size) reach here, never a timer.
  void _scheduleSwarm() {
    if (_swarmSyncScheduled) return;
    _swarmSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _swarmSyncScheduled = false;
      if (mounted) _syncSwarm();
    });
  }

  void _syncSwarm() {
    final layout = _layout;
    if (layout == null) return;
    final text = _step == V2CaptureStep.capture ? _controller.text.length : 0;
    switch (_step) {
      case V2CaptureStep.capture:
        _swarm.form(
          SwarmFormation.field(
            count: MemorySwarm.dotsForText(text),
            center: layout.fieldCenter,
          ),
        );
      case V2CaptureStep.saved ||
          V2CaptureStep.recall ||
          V2CaptureStep.archived:
        _swarm.form(
          SwarmFormation.fragment(center: layout.fragmentCenter),
          duration: V2Motion.gather,
        );
      case V2CaptureStep.processing:
        if (_processingFailed) {
          _swarm.form(SwarmFormation.fragment(center: layout.fragmentCenter));
          return;
        }
        final groups = (_swarm.visible / 30).round().clamp(3, 6);
        final formation = switch (_processingStage) {
          0 => SwarmFormation.clusters(
            center: layout.processCenter,
            groups: groups,
          ),
          1 => SwarmFormation.linked(
            center: layout.processCenter,
            groups: groups,
          ),
          2 => SwarmFormation.rows(
            rect: layout.textRect,
            lineHeight: layout.lineHeight,
            titleGap: layout.titleGap,
          ),
          _ => SwarmFormation.page(
            rect: layout.textRect,
            lineHeight: layout.lineHeight,
            titleGap: layout.titleGap,
          ),
        };
        _swarm.form(formation, duration: V2Motion.stage);
      case V2CaptureStep.reveal:
        _swarm.form(
          SwarmFormation.dissolve(
            rect: layout.textRect,
            lineHeight: layout.lineHeight,
            titleGap: layout.titleGap,
          ),
          duration: _freshReveal ? V2Motion.reveal : Duration.zero,
          stagger: .7,
        );
    }
  }

  void _voicePulse(double level) {
    _swarm.setLevel(level);
    _voiceDecay?.cancel();
    _voiceDecay = Timer(const Duration(milliseconds: 260), () {
      if (mounted) _swarm.setLevel(0);
    });
  }

  // ---------------------------------------------------------------- draft

  Future<void> _restoreDraft() async {
    if (!mounted) return;
    setState(() {
      _draftLoadFailed = false;
      _draftDiscardFailed = false;
    });
    try {
      final draft = await _autosave.repository.loadDraft().timeout(
        const Duration(seconds: 8),
      );
      if (!mounted) return;
      if (draft != null && draft.rawText.isNotEmpty) {
        _draft = draft;
        _controller.text = draft.rawText;
        _usedVoice = draft.inputMode == DreamInputMode.voice;
        final resume = await showV2Dialog<bool>(
          context,
          title: '쓰던 꿈이 남아 있어요',
          body: '남겨 둔 기억을 이어서 적을까요?',
          dismissible: false,
          actions: (dialogContext) => [
            V2Button.secondary(
              label: '새로 쓰기',
              size: V2ButtonSize.compact,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            V2Button(
              label: '이어서 쓰기',
              size: V2ButtonSize.compact,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
        if (!mounted) return;
        if (resume == false) {
          await _discardDraft();
          return;
        }
      }
      if (mounted) setState(() => _draftReady = true);
      _scheduleSwarm();
    } on Object {
      if (mounted) setState(() => _draftLoadFailed = true);
    }
  }

  Future<void> _discardDraft() async {
    setState(() => _draftDiscardFailed = false);
    try {
      await _autosave.discard();
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _draft = null;
        _usedVoice = false;
        _draftReady = true;
      });
      _scheduleSwarm();
    } on Object {
      if (mounted) setState(() => _draftDiscardFailed = true);
    }
  }

  DreamDraft _snapshot() {
    final now = DateTime.now();
    return _draft = DreamDraft(
      id: _draft?.id ?? const Uuid().v4(),
      rawText: _controller.text,
      inputMode: _usedVoice ? DreamInputMode.voice : DreamInputMode.text,
      dreamDate: _draft?.dreamDate ?? _dreamDate(now),
      isBackfill: _draft?.isBackfill ?? false,
      updatedAt: now.toUtc(),
    );
  }

  // ---------------------------------------------------------------- voice

  Future<void> _toggleRecording() async {
    if (_recording) {
      _stopRecording();
      return;
    }
    final session = ++_speechSession;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _recording = true;
      _voiceHasText = false;
      _voiceNotice = null;
      _voicePrefix = _controller.text.trimRight();
    });
    final previousSpeech = _speechSubscription;
    if (previousSpeech != null) await previousSpeech.cancel();
    if (!mounted || session != _speechSession) return;
    try {
      _speechSubscription = _speech.updates.listen(
        (update) {
          if (!mounted || !_recording || session != _speechSession) return;
          final text = update.text;
          final before = _controller.text.length;
          if (text != null && text.isNotEmpty) {
            _usedVoice = true;
            _voiceHasText = true;
            _controller.text =
                '${_voicePrefix.isEmpty ? '' : '$_voicePrefix\n'}$text';
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          }
          // The real level when the platform reports one; otherwise the
          // amount newly recognized is the voice's visible energy.
          if (update.rms > 0) {
            _voicePulse(update.rms);
          } else if (_controller.text.length > before) {
            _voicePulse(
              math.min(1, .35 + (_controller.text.length - before) * .05),
            );
          }
          if (update.code != null) _speechFailed();
          if (update.stopped) {
            _stopRecording();
            if (!_voiceHasText) _speechMessage('들리지 않았어요. 직접 적어보시겠어요?');
          }
        },
        onError: (Object _) {
          if (session == _speechSession) _speechFailed();
        },
      );
      await _speech.start();
    } on Object {
      if (session == _speechSession) _speechFailed();
    }
  }

  void _stopRecording() {
    _speechSession++;
    unawaited(_speech.stop());
    _voiceDecay?.cancel();
    _swarm.setLevel(0);
    if (mounted) setState(() => _recording = false);
  }

  void _speechFailed() {
    if (!mounted || !_recording) return;
    _stopRecording();
    _speechMessage(
      '이 기기에서 음성 인식을 사용할 수 없어요. 직접 적거나 iPhone의 마이크·음성 인식 권한을 확인해 주세요.',
    );
  }

  void _speechMessage(String message) {
    if (!mounted) return;
    setState(() => _voiceNotice = message);
  }

  void _onEditorValueChanged() {
    if (!_draftReady || _submitting || _step != V2CaptureStep.capture) return;
    final text = _controller.text;
    if (text == _lastDraftText) return;
    _lastDraftText = text;
    _autosave.changed(_snapshot(), immediate: _recording);
    // Typing is an input event: the field answers it with dots.
    final layout = _layout;
    if (layout != null) {
      _swarm.form(
        SwarmFormation.field(
          count: MemorySwarm.dotsForText(text.length),
          center: layout.fieldCenter,
        ),
      );
    }
    setState(() {});
  }

  void _onEditorFocus() {
    if (_editorFocus.hasFocus && _recording) _stopRecording();
  }

  // ---------------------------------------------------------------- submit

  Future<void> _saveDream() async {
    if (!_draftReady || _submitting) return;
    if (_controller.text.trim().isEmpty) {
      showV2Toast(context, '장면 하나만 적어도 괜찮아요.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _stopRecording();
    setState(() => _submitting = true);
    final draft = _snapshot();
    try {
      final dreamId = await _autosave.submit(draft);
      AppLog.event('dream_saved', {
        'dream_id': dreamId,
        'mode': draft.inputMode.databaseValue,
      });
      if (!mounted) return;
      v2Haptic(V2Haptic.success);
      setState(() {
        _dreamId = dreamId;
        _step = V2CaptureStep.saved;
      });
      _scheduleSwarm();
    } on Object {
      if (!mounted) return;
      showV2Toast(context, '꿈을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startProcessing({bool skip = false}) async {
    if (_submittingGeneration ||
        (_step == V2CaptureStep.processing && !_processingFailed)) {
      return;
    }
    final dreamId = _dreamId;
    if (dreamId == null) return;
    final retrying = _processingFailureCode == 'job_failed';
    _retryRequestPending = retrying;
    _submittingGeneration = true;
    setState(() {
      _step = V2CaptureStep.processing;
      _processingStage = 0;
      _stageLabel = null;
      _attempt = 1;
      _jobDone = false;
      _processingFailed = false;
      _processingFailureCode = null;
      _connectionInterrupted = false;
      _submissionUncertain = false;
    });
    _scheduleSwarm();
    _jobSubscription?.close();
    _jobSubscription = null;
    final engine = ref.read(engineClientProvider);
    final repository = ref.read(repositoryProvider);
    try {
      if (!retrying) {
        await repository.answerRecall(
          dreamId,
          skip ? {} : Map<String, String>.of(_answers),
        );
        AppLog.event(skip ? 'recall_skipped' : 'recall_answered', {
          'dream_id': dreamId,
        });
      }
      _engineIdempotencyKey ??= dreamId;
      if (retrying) {
        await engine.retry(dreamId);
        final dreams = await repository
            .watchDreams(DreamStatusFilter.all)
            .first;
        final current = dreams.where((d) => d.id == dreamId).firstOrNull;
        if (current?.status == DreamStatus.failed ||
            current?.status == DreamStatus.queued) {
          await repository.answerRecall(
            dreamId,
            Map<String, String>.of(_answers),
          );
        }
      } else {
        await engine.enqueue(dreamId, _engineIdempotencyKey!);
      }
      if (!mounted) return;
      _retryRequestPending = false;
      ref.invalidate(jobProgressProvider(dreamId));
      _observeProcessing();
    } on GenerationSettingsPending {
      if (mounted) {
        setState(() {
          _step = V2CaptureStep.saved;
          _processingFailed = false;
        });
        _scheduleSwarm();
        showV2Toast(
          context,
          '원고 설정을 동기화한 뒤 장면을 만들 수 있어요. 설정에서 반영 상태를 확인해 주세요.',
        );
      }
      return;
    } on TrialLimitException catch (error) {
      if (!mounted) return;
      _failProcessing(error.code);
      return;
    } on Object {
      if (!mounted) return;
      _observeProcessing();
      setState(() {
        _connectionInterrupted = true;
        _submissionUncertain = true;
      });
      return;
    } finally {
      _submittingGeneration = false;
    }
  }

  void _observeProcessing() {
    final dreamId = _dreamId;
    if (!mounted || dreamId == null || _jobSubscription != null) return;
    _jobSubscription = ref.listenManual(jobProgressProvider(dreamId), (
      _,
      next,
    ) {
      if (!mounted) return;
      if (next.hasError) {
        setState(() => _connectionInterrupted = true);
      } else if (next.hasValue) {
        _onJobProgress(next.value);
      }
    }, fireImmediately: true);
  }

  void _reconnectProcessing() {
    final dreamId = _dreamId;
    if (dreamId == null) return;
    ref.invalidate(jobProgressProvider(dreamId));
    setState(() => _connectionInterrupted = false);
  }

  Future<void> _confirmSubmission() async {
    final dreamId = _dreamId;
    if (dreamId == null || _submittingGeneration) return;
    _submittingGeneration = true;
    try {
      final engine = ref.read(engineClientProvider);
      if (_retryRequestPending) {
        await engine.retry(dreamId);
      } else {
        await engine.enqueue(dreamId, _engineIdempotencyKey ?? dreamId);
      }
      _retryRequestPending = false;
      _submissionUncertain = false;
      if (mounted) _reconnectProcessing();
    } on TrialLimitException catch (error) {
      _failProcessing(error.code);
    } on Object {
      if (mounted) setState(() => _connectionInterrupted = true);
    } finally {
      _submittingGeneration = false;
    }
  }

  void _failProcessing(String code) {
    if (!mounted || _processingFailed) return;
    AppLog.event('processing_failed', {
      'stage': _processingStage,
      'code': code,
    });
    setState(() {
      _processingFailed = true;
      _processingFailureCode = code;
    });
    _scheduleSwarm();
  }

  void _onJobProgress(JobProgress? progress) {
    if (!mounted || progress == null) return;
    if (progress.status == JobStatus.failed) {
      _failProcessing('job_failed');
      return;
    }
    _connectionInterrupted = _submissionUncertain;
    _processingFailed = false;
    _processingFailureCode = null;
    if (progress.status == JobStatus.done && progress.archivedOnly) {
      _jobDone = true;
      AppLog.event('dream_archived_only', {'dream_id': progress.dreamId});
      setState(() => _step = V2CaptureStep.archived);
      _scheduleSwarm();
      return;
    }
    setState(() {
      _processingStage = switch (progress.type) {
        JobType.extract => 0,
        JobType.link => 1,
        JobType.plan || JobType.write || JobType.linkPatch => 2,
        JobType.validate || JobType.commit || JobType.remember => 3,
      };
      _stageLabel = progress.stageLabel;
      _attempt = progress.attempt;
    });
    _scheduleSwarm();
    if (progress.status == JobStatus.done &&
        (progress.type == JobType.commit ||
            progress.type == JobType.remember)) {
      _jobDone = true;
      if (mounted) setState(() {});
      _finishProcessingIfReady();
    }
  }

  void _prepareRevealData() {
    final dreamId = _dreamId;
    if (dreamId == null ||
        !_jobDone ||
        _step == V2CaptureStep.archived ||
        _revealScene != null ||
        _revealScheduled) {
      return;
    }
    final volume = ref.watch(activeVolumeProvider).value;
    if (volume == null) return;
    final dreams = ref.watch(dreamsProvider(DreamStatusFilter.all)).value;
    final dream = dreams?.where((item) => item.id == dreamId).firstOrNull;
    if (dream?.status == DreamStatus.archivedOnly) {
      if (!_archiveScheduled) {
        _archiveScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _archiveScheduled = false;
          if (!mounted || !_jobDone) return;
          AppLog.event('dream_archived_only', {'dream_id': dreamId});
          setState(() => _step = V2CaptureStep.archived);
          _scheduleSwarm();
        });
      }
      return;
    }
    final scenes = ref.watch(scenesProvider(volume.id)).value;
    if (scenes == null) return;
    Scene? revealScene;
    for (final scene in scenes.reversed) {
      if (scene.sourceDreamIds.contains(dreamId)) {
        revealScene = scene;
        break;
      }
    }
    if (revealScene == null) return;
    final passages = ref.watch(passagesProvider(revealScene.id)).value;
    final progressEvents = ref.watch(recentProgressProvider(volume.id)).value;
    final decisions = ref.watch(linkDecisionsProvider(dreamId)).value;
    if (passages == null ||
        passages.isEmpty ||
        progressEvents == null ||
        decisions == null) {
      return;
    }
    ProgressEvent? event;
    for (final candidate in progressEvents) {
      if (candidate.dreamId == dreamId && candidate.deltaMu > 0) {
        event = candidate;
        break;
      }
    }
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted) return;
      setState(() {
        _revealScene = revealScene;
        _revealPassages = passages;
        _revealDecision = decisions.firstOrNull;
        _revealGrowthEventId = event?.id;
        _revealDeltaPercent = event == null
            ? 0
            : (event.deltaMu / volume.targetMu * 100).round();
      });
      _finishProcessingIfReady();
    });
  }

  void _finishProcessingIfReady() {
    if (!mounted ||
        _step == V2CaptureStep.reveal ||
        _revealClaimScheduled ||
        _revealClaimBusy ||
        _processingFailed ||
        !_jobDone ||
        _processingStage < 3 ||
        _revealScene == null) {
      return;
    }
    if (!_canPresent) return;
    _revealClaimScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealClaimScheduled = false;
      if (_canPresent) unawaited(_consumeReveal());
    });
  }

  bool get _canPresent =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      TickerMode.valuesOf(context).enabled &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  Future<void> _consumeReveal({bool retry = false}) async {
    final scene = _revealScene;
    if (scene == null || _revealClaimBusy || !_canPresent) return;
    setState(() => _revealClaimBusy = true);
    try {
      final fresh = await ref
          .read(repositoryProvider)
          .consumePresentation(
            volumeId: scene.volumeId,
            kind: PresentationKind.reveal,
            sourceId: scene.id,
          );
      // V2 presentation split: the reveal states the real increase; the
      // growth receipt is left for Home, where new dots join the manuscript
      // (DESIGN_V2.md §6.4). Receipts are device UI state, not data.
      final freshGrowth = fresh && _revealGrowthEventId != null;
      if (!_canPresent) return;
      setState(() {
        _freshReveal = fresh && !retry;
        _freshGrowth = freshGrowth && !retry;
        _presentationError = false;
        _step = V2CaptureStep.reveal;
      });
      _scheduleSwarm();
      if (_freshReveal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_canPresent || _step != V2CaptureStep.reveal) return;
          AppLog.event('processing_completed', {'dream_id': _dreamId});
          AppLog.event('reveal_viewed', {
            'dream_id': _dreamId,
            'scene_id': scene.id,
          });
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          // The manuscript is ready even if this device cannot save a UI
          // receipt. Never regenerate it or block access to the Reader.
          _freshReveal = false;
          _presentationError = true;
          _step = V2CaptureStep.reveal;
        });
        _scheduleSwarm();
      }
    } finally {
      if (mounted) setState(() => _revealClaimBusy = false);
    }
  }

  Future<void> _finishRecall({bool skip = false}) async {
    if (_savingRecall || _dreamId == null) return;
    setState(() => _savingRecall = true);
    try {
      await ref
          .read(repositoryProvider)
          .saveRecallAnswers(
            _dreamId!,
            skip ? {} : Map<String, String>.of(_answers),
          );
      if (mounted) {
        setState(() {
          if (skip) _answers.clear();
          _step = V2CaptureStep.saved;
        });
        _scheduleSwarm();
      }
    } on Object {
      if (mounted) {
        showV2Toast(context, '보강한 기억을 저장하지 못했어요. 답변은 그대로 남아 있어요.');
      }
    } finally {
      if (mounted) setState(() => _savingRecall = false);
    }
  }

  Future<void> _decideLink(String label) async {
    final decision = _revealDecision;
    if (decision == null || _savingLink) return;
    final choice = switch (label) {
      '같은 사람' => LinkChoice.same,
      '다른 사람' => LinkChoice.different,
      _ => LinkChoice.unsure,
    };
    setState(() => _savingLink = true);
    try {
      await ref.read(repositoryProvider).decideLink(decision.id, choice);
      AppLog.event('link_decided', {
        'dream_id': decision.dreamId,
        'mode': choice.name,
      });
      if (mounted) setState(() => _linkChoice = label);
    } on Object {
      if (mounted) showV2Toast(context, '연결 선택을 저장하지 못했어요.');
    } finally {
      if (mounted) setState(() => _savingLink = false);
    }
  }

  // ---------------------------------------------------------------- build

  V2Mood get _mood => switch (_step) {
    V2CaptureStep.capture => V2Mood.capture,
    V2CaptureStep.processing => V2Mood.processing,
    V2CaptureStep.reveal => V2Mood.reveal,
    _ => V2Mood.capture,
  };

  @override
  Widget build(BuildContext context) {
    _prepareRevealData();
    _finishProcessingIfReady();
    final energy = _step == V2CaptureStep.capture
        ? math.min(1.0, _controller.text.length / 280) + (_recording ? .25 : 0)
        : 0.0;
    return Scaffold(
      backgroundColor: V2Color.paper,
      resizeToAvoidBottomInset: _step == V2CaptureStep.capture,
      body: V2Atmosphere(
        mood: _mood,
        energy: energy,
        stage: _processingStage,
        duration: _step == V2CaptureStep.processing
            ? V2Motion.stage
            : V2Motion.page,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _SwarmLayout.of(context, constraints.biggest);
            if (_layout != layout) {
              _layout = layout;
              _scheduleSwarm();
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: ExcludeSemantics(
                    child: MemorySwarmView(swarm: _swarm),
                  ),
                ),
                Column(
                  children: [
                    _FlowHeader(
                      dreamNumber: widget.dreamNumber,
                      step: _step,
                      freshReveal: _freshReveal,
                      onClose: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        layoutBuilder: (current, outgoing) => Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            for (final child in outgoing)
                              IgnorePointer(
                                child: ExcludeSemantics(child: child),
                              ),
                            ?current,
                          ],
                        ),
                        duration:
                            V2Motion.reduced(context) ||
                                _step == V2CaptureStep.capture ||
                                (_step == V2CaptureStep.reveal && !_freshReveal)
                            ? Duration.zero
                            : V2Motion.page,
                        switchInCurve: V2Motion.settle,
                        switchOutCurve: V2Motion.exit,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Align(
                          key: ValueKey(_step),
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: V2Space.contentMax,
                            ),
                            child: switch (_step) {
                              V2CaptureStep.capture => _buildCapture(layout),
                              V2CaptureStep.saved => _buildSaved(layout),
                              V2CaptureStep.recall => _buildRecall(layout),
                              V2CaptureStep.processing => _buildProcessing(
                                layout,
                              ),
                              V2CaptureStep.reveal => _buildReveal(layout),
                              V2CaptureStep.archived => _buildArchived(layout),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCapture(_SwarmLayout layout) {
    if (!_draftReady) {
      final failed = _draftLoadFailed || _draftDiscardFailed;
      return _StepBody(
        key: const ValueKey('v2-capture-draft-loading'),
        topSpace: layout.stageHeight,
        title: failed ? '쓰던 꿈을\n안전하게 열지 못했어요' : '쓰던 꿈을\n확인하고 있어요',
        body: failed ? '기존 기록은 지우지 않았어요. 다시 확인하거나 닫은 뒤 돌아와 주세요.' : null,
        actions: failed
            ? V2PrimaryAction(
                label: '다시 확인하기',
                onPressed: _draftDiscardFailed ? _discardDraft : _restoreDraft,
              )
            : null,
      );
    }
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final largeType = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AbsorbPointer(
      key: const ValueKey('v2-capture'),
      absorbing: !_draftReady || _submitting,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          V2Space.gutter,
          0,
          V2Space.gutter,
          keyboardOpen ? V2Space.sm : math.max(bottom, V2Space.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: layout.stageHeight),
            if (!keyboardOpen) ...[
              // Display type is already large; like an iOS large title it
              // grows only so far, so the editor keeps its room at the
              // largest system text sizes.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.5,
                child: Semantics(
                  header: true,
                  child: const Text('어젯밤,\n무엇을 보았나요?', style: V2Type.display),
                ),
              ),
            ],
            if (!keyboardOpen && (!largeType || _voiceNotice != null)) ...[
              const SizedBox(height: V2Space.xs),
              Semantics(
                liveRegion: _voiceNotice != null,
                child: Text(
                  v2KeepAll(
                    _voiceNotice ?? '장면 하나만 기억나도 괜찮아요. 적거나 말한 만큼 도트가 모여요.',
                  ),
                  style: V2Type.bodySmall,
                ),
              ),
              const SizedBox(height: V2Space.lg),
            ] else if (!keyboardOpen)
              const SizedBox(height: V2Space.md),
            Expanded(
              key: const ValueKey('v2-capture-editor-slot'),
              child: RepaintBoundary(
                child: V2CaptureField(
                  fieldKey: const ValueKey('v2-dream-editor'),
                  controller: _controller,
                  focusNode: _editorFocus,
                  recording: _recording,
                  energy: math.min(1, _controller.text.length / 280),
                  hint: kIsWeb ? '떠오르는 대로 적어 보세요…' : '말하거나 적어 보세요…',
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              key: const ValueKey('v2-capture-autosave-status'),
              valueListenable: _autosave.saveFailed,
              builder: (context, failed, _) => failed
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          '자동 저장하지 못했어요. 이 화면을 닫지 말고 내용을 복사해 주세요.',
                          style: V2Type.bodySmall.copyWith(
                            color: V2Color.alert,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: V2Space.md),
            Row(
              key: const ValueKey('v2-capture-actions'),
              children: [
                if (kIsWeb && !keyboardOpen) ...[
                  V2IconButton(
                    icon: Icons.mic_none_rounded,
                    semanticLabel: '음성 입력 안내 · iPhone 앱 전용 녹음',
                    onPressed: () => Navigator.of(
                      context,
                    ).push(v2Route(const V2VoicePage())),
                  ),
                  const SizedBox(width: V2Space.sm),
                ],
                if (!kIsWeb && (!keyboardOpen || _recording)) ...[
                  V2RecordButton(
                    recording: _recording,
                    level: _voiceLevel,
                    onPressed: _toggleRecording,
                  ),
                  const SizedBox(width: V2Space.sm),
                ],
                Expanded(
                  key: const ValueKey('v2-capture-save-action'),
                  child: V2Button(
                    label: '꿈 저장하기',
                    loading: _submitting,
                    loadingLabel: '저장하는 중',
                    expand: true,
                    haptic: V2Haptic.none,
                    onPressed: _saveDream,
                  ),
                ),
              ],
            ),
            if (_recording) ...[
              const SizedBox(height: V2Space.xs),
              Semantics(
                liveRegion: true,
                child: V2Meta(
                  ref.watch(v2VoiceNoteProvider) ?? '듣고 있어요  ·  한 번 더 누르면 멈춰요',
                  color: ref.watch(v2VoiceNoteProvider) == null
                      ? null
                      : V2Color.sky700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaved(_SwarmLayout layout) => _StepBody(
    key: const ValueKey('v2-saved'),
    topSpace: layout.stageHeight,
    eyebrow: '기억 조각 하나',
    title: '꿈이 저장됐어요',
    body: '떠오른 만큼 남겼다면 충분해요.\n지금 이야기로 만들지 않아도 괜찮아요.',
    note: _answers.isNotEmpty ? '보강한 기억도 함께 사용할게요.' : null,
    actions: V2ActionStack(
      primary: V2Button(
        label: '장면 만들기',
        expand: true,
        haptic: V2Haptic.medium,
        onPressed: () => _startProcessing(skip: _answers.isEmpty),
      ),
      secondary: [
        V2Button.glass(
          label: '기억 더 보강하기',
          onPressed: () {
            setState(() => _step = V2CaptureStep.recall);
            _scheduleSwarm();
          },
        ),
        V2TextAction(label: '나중에 만들기', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );

  Widget _buildRecall(_SwarmLayout layout) {
    const questions = [
      ('light', '밝았나요, 어두웠나요?', ['밝음', '어두움', '모름']),
      ('company', '누군가 함께 있었나요?', ['혼자', '아는 사람', '모르는 사람', '모름']),
      ('feeling', '가장 강했던 감정은?', ['불안', '그리움', '설렘', '두려움', '평온', '모름']),
    ];
    final answered = questions.where((q) => _answers.containsKey(q.$1)).length;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      key: const ValueKey('v2-recall'),
      padding: EdgeInsets.fromLTRB(
        V2Space.gutter,
        layout.stageHeight + V2Space.sm,
        V2Space.gutter,
        math.max(bottom, V2Space.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V2StepProgress(
            steps: questions.length,
            current: answered.toDouble(),
            semanticsLabel: '질문 ${questions.length}개 중 $answered개 답함',
          ),
          const SizedBox(height: V2Space.lg),
          Semantics(
            header: true,
            child: const Text('기억의 빈자리만\n조금 더 확인할게요', style: V2Type.display),
          ),
          const SizedBox(height: V2Space.xs),
          const Text('생각나지 않으면 모름을 골라도 돼요.', style: V2Type.bodySmall),
          const SizedBox(height: V2Space.xl),
          for (final question in questions) ...[
            Text(question.$2, style: V2Type.headline),
            const SizedBox(height: V2Space.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final answer in question.$3)
                  V2ChoiceChip(
                    label: answer,
                    selected: _answers[question.$1] == answer,
                    onSelected: () =>
                        setState(() => _answers[question.$1] = answer),
                  ),
              ],
            ),
            const SizedBox(height: V2Space.xl),
          ],
          V2Button(
            label: '보강 마치기',
            expand: true,
            loading: _savingRecall,
            loadingLabel: '기억 저장 중',
            onPressed: _savingRecall ? null : _finishRecall,
          ),
          const SizedBox(height: V2Space.xs),
          Center(
            child: V2TextAction(
              label: '전체 건너뛰기',
              onPressed: _savingRecall ? null : () => _finishRecall(skip: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing(_SwarmLayout layout) {
    if (_processingFailed) {
      final trialLimit =
          _processingFailureCode == 'trial_user_daily_limit' ||
          _processingFailureCode == 'trial_global_daily_limit';
      return _StepBody(
        key: const ValueKey('v2-processing-failed'),
        topSpace: layout.stageHeight,
        eyebrow: '기억 조각은 그대로예요',
        title: trialLimit ? '오늘의 체험 횟수를\n모두 사용했어요' : '장면을 만들지 못했어요',
        body: '꿈은 보관함에 저장되어 있어요.',
        actions: V2ActionStack(
          primary: trialLimit
              ? V2Button(
                  label: '보관함에서 나중에 보기',
                  expand: true,
                  onPressed: () => Navigator.pop(context),
                )
              : V2Button(
                  label: '다시 시도',
                  expand: true,
                  onPressed: _startProcessing,
                ),
          secondary: [
            if (!trialLimit)
              V2TextAction(
                label: '보관함에서 나중에 보기',
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
      );
    }
    final stage = _processingStage.clamp(0, 3);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final retryNote = _attempt > 1 ? '  ·  $_attempt번째 시도' : '';
    return Semantics(
      key: const ValueKey('v2-processing'),
      liveRegion: true,
      label: '소설을 만들고 있어요, ${v2StageTitles[stage]}',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          V2Space.gutter,
          0,
          V2Space.gutter,
          math.max(bottom, V2Space.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 5),
            // V1's Thinking Orb keeps turning while the real job runs; it
            // sits below the gathering dots so the stages stay readable.
            const Center(
              key: ValueKey('v2-processing-orb'),
              child: V2ThinkingOrb(),
            ),
            const Spacer(flex: 3),
            V2StepProgress(
              steps: 4,
              current: _jobDone ? 4 : stage + .55,
              semanticsLabel: '4단계 중 ${stage + 1}단계',
            ),
            const SizedBox(height: V2Space.md),
            AnimatedSwitcher(
              duration: V2Motion.of(context, V2Motion.base),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                _connectionInterrupted ? '연결을 확인하고 있어요' : v2StageTitles[stage],
                key: ValueKey('$stage$_connectionInterrupted'),
                style: V2Type.title,
              ),
            ),
            const SizedBox(height: V2Space.xxs),
            V2Meta('${_stageLabel ?? '기억 조각을 펼치는 중'}$retryNote'),
            if (_connectionInterrupted) ...[
              const SizedBox(height: V2Space.md),
              V2Notice(
                message: '생성 결과를 다시 확인해요. 새로 만들지 않아요.',
                icon: Icons.wifi_tethering_error_rounded,
                actions: [
                  V2TextAction(
                    label: '상태 다시 확인',
                    onPressed: _reconnectProcessing,
                  ),
                  if (_submissionUncertain)
                    V2TextAction(
                      label: '접수 다시 확인',
                      onPressed: _confirmSubmission,
                    ),
                ],
              ),
            ],
            const SizedBox(height: V2Space.md),
            Align(
              alignment: Alignment.centerLeft,
              child: V2TextAction(
                label: '나중에 확인하기',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReveal(_SwarmLayout layout) {
    final scene = _revealScene!;
    final first = _revealPassages.firstOrNull;
    final scenes = ref.watch(scenesProvider(scene.volumeId)).value;
    final isFirstScene = scenes?.length == 1 && scenes!.single.id == scene.id;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final animate = _freshReveal && !V2Motion.reduced(context);
    final padBottom = math.max(bottom, V2Space.lg);
    return LayoutBuilder(
      key: const ValueKey('v2-reveal'),
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          V2Space.gutter,
          layout.cardTop,
          V2Space.gutter,
          padBottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              constraints.maxHeight - layout.cardTop - padBottom,
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RevealCard(
                  animate: animate,
                  meta: !_freshReveal
                      ? '원고에 보관된 장면이에요'
                      : isFirstScene
                      ? '내 꿈에서 시작한 첫 장면이에요'
                      : '꿈이 한 장면이 되었어요',
                  dreamNumber: widget.dreamNumber,
                  sceneNumber: widget.sceneNumber,
                  delta: !isFirstScene && _freshReveal && _freshGrowth
                      ? _revealDeltaPercent
                      : null,
                  title: scene.title ?? '제목 없는 장면',
                  passage: first?.text,
                  originLabel: first?.origin == PassageOrigin.dream
                      ? '꿈에서 온 첫 문장'
                      : '원고의 첫 문장',
                  metaHeight: layout.metaHeight,
                ),
                if (isFirstScene) ...[
                  const SizedBox(height: V2Space.md),
                  const Text(
                    '먼저 천천히 읽어보세요. 꿈 원문은 보관함에 따로 남아 있어요.',
                    style: V2Type.bodySmall,
                  ),
                ],
                if (_presentationError) ...[
                  const SizedBox(height: V2Space.md),
                  const V2Notice(
                    message: '화면 상태를 저장하지 못했어요. 장면은 그대로 읽을 수 있어요.',
                  ),
                ],
                const SizedBox(height: V2Space.lg),
                const Spacer(),
                V2ActionStack(
                  primary: V2Button(
                    label: _freshReveal ? '새 장면 읽기' : '장면 읽기',
                    expand: true,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () =>
                        Navigator.of(context).pushReplacement<bool, bool>(
                          v2Route(
                            V2ReaderScreen(
                              volumeId: scene.volumeId,
                              initialSceneId: scene.id,
                            ),
                          ),
                          result: true,
                        ),
                  ),
                  secondary: [
                    if (_presentationError)
                      V2TextAction(
                        label: '화면 상태 다시 저장',
                        onPressed: _revealClaimBusy
                            ? null
                            : () => _consumeReveal(retry: true),
                      ),
                    V2TextAction(
                      label: '장면 조정하기',
                      onPressed: _showDirectionSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchived(_SwarmLayout layout) => _StepBody(
    key: const ValueKey('v2-archived'),
    topSpace: layout.stageHeight,
    eyebrow: '보관함에 저장됨',
    title: '이번 꿈은 아직\n원고와 이어지지 않았어요',
    body: '원문은 보관함에 안전하게 남겨두었습니다.\n다음 꿈이 새로운 연결을 만들 수 있어요.',
    actions: V2PrimaryAction(
      label: '원고로 돌아가기',
      onPressed: () => Navigator.pop(context, true),
    ),
  );

  Future<void> _showDirectionSheet() => showV2Sheet<void>(
    context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, update) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('장면을 조정하기', style: V2Type.title),
            if (_revealDecision != null) ...[
              const SizedBox(height: V2Space.lg),
              Text(
                '오늘의 ‘${_revealDecision!.payload['label'] ?? '기억 속 존재'}’,\n'
                '${_revealDecision!.payload['candidate_label'] ?? '앞 장면의 존재'}일까요?',
                style: V2Type.body.copyWith(color: V2Color.ink),
              ),
              const SizedBox(height: V2Space.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in const ['같은 사람', '다른 사람', '모르겠음'])
                    V2ChoiceChip(
                      label: choice,
                      selected: _linkChoice == choice,
                      onSelected: _savingLink
                          ? null
                          : () async {
                              final saving = _decideLink(choice);
                              update(() {});
                              await saving;
                              if (sheetContext.mounted) update(() {});
                            },
                    ),
                ],
              ),
            ],
            const SizedBox(height: V2Space.lg),
            V2Button.glass(
              label: '장면의 위치 바꾸기',
              expand: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                _showPlacementSheet();
              },
            ),
            const SizedBox(height: V2Space.xs),
            V2Button(
              label: '완료',
              expand: true,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );

  void _showPlacementSheet() {
    showV2Sheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('이 장면을 어디에 둘까요?', style: V2Type.title),
          const SizedBox(height: V2Space.md),
          _SheetRow(
            title: '사이 장면으로 넣기',
            onTap: () async {
              await ref
                  .read(repositoryProvider)
                  .changePlacement(_revealScene!.id, PlacementKind.interlude);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
          _SheetRow(
            title: '원고에서 빼기',
            subtitle: '꿈은 보관함에 그대로 남아요.',
            onTap: () async {
              final dreamId = _dreamId;
              if (dreamId != null) {
                await ref
                    .read(repositoryProvider)
                    .removeDreamFromManuscript(dreamId);
              }
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    );
  }
}

/// Where the swarm lives for each step, shared by the swarm and the views
/// so processing rows end exactly where the reveal text begins.
@immutable
class _SwarmLayout {
  const _SwarmLayout({
    required this.size,
    required this.fieldCenter,
    required this.fragmentCenter,
    required this.processCenter,
    required this.textRect,
    required this.cardTop,
    required this.stageHeight,
    required this.metaHeight,
    required this.lineHeight,
    required this.titleGap,
  });

  factory _SwarmLayout.of(BuildContext context, Size size) {
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    const header = 64.0;
    final top = padding.top + header;
    // Keyboard or very large text: the memory field gives up height first so
    // the editor and the save action keep theirs.
    final compact = keyboard || scale > 1.35;
    final double stageHeight = compact
        ? 92.0
        : (size.height * .19).clamp(132.0, 190.0);
    final contentWidth = math.min(size.width, V2Space.contentMax);
    final left = (size.width - contentWidth) / 2 + V2Space.gutter;
    final cardTop = 12.0;
    const cardPadding = 24.0;
    final metaHeight = 52.0 * math.min(scale, 1.6);
    final textTop = top + cardTop + cardPadding + metaHeight;
    final lineHeight = 17.0 * 1.84 * math.min(scale, 2.0);
    final titleGap = 31.0 * math.min(scale, 2.0) + 22;
    return _SwarmLayout(
      size: size,
      fieldCenter: Offset(size.width / 2, top + stageHeight * .5),
      fragmentCenter: Offset(size.width / 2, top + stageHeight * .52),
      processCenter: Offset(size.width / 2, top + (size.height - top) * .30),
      textRect: Rect.fromLTWH(
        left + cardPadding,
        textTop,
        contentWidth - V2Space.gutter * 2 - cardPadding * 2,
        titleGap + lineHeight * 5,
      ),
      cardTop: cardTop,
      stageHeight: stageHeight,
      metaHeight: metaHeight,
      lineHeight: lineHeight,
      titleGap: titleGap,
    );
  }

  final Size size;
  final Offset fieldCenter;
  final Offset fragmentCenter;
  final Offset processCenter;
  final Rect textRect;
  final double cardTop;
  final double stageHeight;
  final double metaHeight;
  final double lineHeight;
  final double titleGap;

  @override
  bool operator ==(Object other) =>
      other is _SwarmLayout &&
      other.size == size &&
      other.fieldCenter == fieldCenter &&
      other.textRect == textRect &&
      other.stageHeight == stageHeight;

  @override
  int get hashCode => Object.hash(size, fieldCenter, textRect, stageHeight);
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.dreamNumber,
    required this.step,
    required this.freshReveal,
    required this.onClose,
  });

  final int dreamNumber;
  final V2CaptureStep step;
  final bool freshReveal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = switch (step) {
      V2CaptureStep.capture => '꿈 기록',
      V2CaptureStep.saved => '저장 완료',
      V2CaptureStep.recall => '기억 보강',
      V2CaptureStep.processing => '장면 만드는 중',
      V2CaptureStep.reveal => freshReveal ? '새 장면' : '저장된 장면',
      V2CaptureStep.archived => '보관함에 저장됨',
    };
    final now = DateTime.now();
    return V2ContextHeader(
      leading: V2IconButton(
        icon: Icons.close_rounded,
        semanticLabel: '닫기',
        onPressed: onClose,
      ),
      title: Semantics(
        label: '꿈 $dreamNumber번, $label',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            V2DotMatrix(
              'DREAM ${dreamNumber.toString().padLeft(3, '0')}',
              pitch: 2,
              color: V2Color.ink2,
            ),
            const SizedBox(height: 5),
            V2Meta(label),
          ],
        ),
      ),
      trailing: SizedBox(
        width: V2Size.touch,
        child: Center(
          child: V2DotMatrix(
            v2DotDate(now),
            pitch: 1.6,
            color: V2Color.ink3,
            semanticsLabel: v2SpokenDate(now),
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.topSpace,
    required this.title,
    this.eyebrow,
    this.body,
    this.note,
    this.actions,
  });

  final double topSpace;
  final String title;
  final String? eyebrow;
  final String? body;
  final String? note;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          V2Space.gutter,
          0,
          V2Space.gutter,
          math.max(bottom, V2Space.lg),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              constraints.maxHeight - math.max(bottom, V2Space.lg),
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topSpace + V2Space.lg),
                if (eyebrow != null) ...[
                  V2Meta(eyebrow!),
                  const SizedBox(height: V2Space.xs),
                ],
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(v2KeepAll(title), style: V2Type.display),
                ),
                if (body != null) ...[
                  const SizedBox(height: V2Space.sm),
                  Text(v2KeepAll(body!), style: V2Type.body),
                ],
                if (note != null) ...[
                  const SizedBox(height: V2Space.sm),
                  V2Meta(note!, color: V2Color.sky700),
                ],
                const SizedBox(height: V2Space.xl),
                const Spacer(),
                ?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reveal paper card. Meta prints first, then the title and the first
/// sentence are uncovered top to bottom as the dot rows dissolve over them.
class _RevealCard extends StatefulWidget {
  const _RevealCard({
    required this.animate,
    required this.meta,
    required this.dreamNumber,
    required this.sceneNumber,
    required this.title,
    required this.passage,
    required this.originLabel,
    required this.metaHeight,
    this.delta,
  });

  final bool animate;
  final String meta;
  final int dreamNumber;
  final int sceneNumber;
  final int? delta;
  final String title;
  final String? passage;
  final String originLabel;
  final double metaHeight;

  @override
  State<_RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<_RevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: V2Motion.reveal + const Duration(milliseconds: 500),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _reveal.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Widget _uncover(double from, double to, Widget child) => AnimatedBuilder(
    animation: _reveal,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(
        ((_reveal.value - from) / (to - from)).clamp(0.0, 1.0),
      );
      if (t >= 1) return child!;
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [
            0,
            (t * 1.15 - .15).clamp(0.0, 1.0),
            (t * 1.15).clamp(0.0, 1.0),
          ],
        ).createShader(rect),
        child: child,
      );
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) => Opacity(
        opacity: Curves.easeOut.transform(
          (_reveal.value / .25).clamp(0.0, 1.0),
        ),
        child: Transform.translate(
          offset: Offset(
            0,
            10 *
                (1 -
                    Curves.easeOut.transform(
                      (_reveal.value / .4).clamp(0.0, 1.0),
                    )),
          ),
          child: child,
        ),
      ),
      child: V2Surface(
        kind: V2SurfaceKind.paper,
        radius: V2Radius.hero,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: widget.metaHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: V2Meta(widget.meta, color: V2Color.sky700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: V2DotMatrix(
                          'DREAM ${widget.dreamNumber.toString().padLeft(3, '0')} > SCENE ${widget.sceneNumber}',
                          pitch: 1.7,
                          color: V2Color.ink3,
                          semanticsLabel:
                              '꿈 ${widget.dreamNumber}번에서 장면 ${widget.sceneNumber}',
                        ),
                      ),
                      const SizedBox(width: V2Space.sm),
                      const Spacer(),
                      if (widget.delta != null)
                        V2DotMatrix(
                          '${widget.delta! >= 0 ? '+' : ''}${widget.delta}%',
                          pitch: 1.9,
                          color: V2Color.sky600,
                          semanticsLabel: '원고 ${widget.delta}% 늘어남',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _uncover(
              .15,
              .45,
              Text(
                v2KeepAll(widget.title),
                style: V2Type.title.copyWith(fontSize: 26, height: 1.2),
              ),
            ),
            const SizedBox(height: 22),
            if (widget.passage != null)
              _uncover(
                .35,
                .95,
                Text(
                  v2KeepAll(widget.passage!),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: V2Type.reading.copyWith(fontSize: 17, height: 1.84),
                ),
              ),
            const SizedBox(height: V2Space.sm),
            _uncover(.85, 1, V2Meta(widget.originLabel)),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => V2Pressable(
    onPressed: onTap,
    semanticLabel: subtitle == null ? title : '$title, $subtitle',
    builder: (context, state) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: V2Color.hairline)),
        color: V2Color.ink.withValues(alpha: .04 * state.sink),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: V2Type.headline),
                if (subtitle != null) Text(subtitle!, style: V2Type.bodySmall),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: V2Color.ink2,
          ),
        ],
      ),
    ),
  );
}

DateTime _dreamDate(DateTime now) {
  final adjusted = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
  return DateTime(adjusted.year, adjusted.month, adjusted.day);
}

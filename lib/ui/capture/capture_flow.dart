import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dream_atmosphere.dart';
import '../../core/design/thinking_orb.dart';
import '../../core/log/app_log.dart';
import '../../data/engine/engine_client.dart';
import '../../data/speech/speech_input.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import 'draft_autosave.dart';
import '../reader/reader_screen.dart';
import '../shared/web_install_guide.dart';

enum CaptureStep { capture, saved, recall, processing, reveal, archived }

class CaptureFlow extends ConsumerStatefulWidget {
  const CaptureFlow({
    super.key,
    required this.dreamNumber,
    required this.sceneNumber,
    this.savedDream,
  });

  final int dreamNumber;
  final int sceneNumber;
  final Dream? savedDream;

  @override
  ConsumerState<CaptureFlow> createState() => _CaptureFlowState();
}

class _CaptureFlowState extends ConsumerState<CaptureFlow>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _editorFocus = FocusNode(debugLabel: 'dream-capture-editor');
  String _lastDraftText = '';
  CaptureStep _step = CaptureStep.capture;
  bool _recording = false;
  bool _recordButtonPressed = false;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _editorFocus.addListener(_onEditorFocus);
    _autosave = DraftAutosave(ref.read(repositoryProvider));
    _controller.addListener(_onEditorValueChanged);
    _speech = ref.read(speechInputProvider);
    final saved = widget.savedDream;
    if (saved != null) {
      _dreamId = saved.id;
      _answers.addAll(saved.recallAnswers);
      _step = saved.status == DreamStatus.queued
          ? CaptureStep.saved
          : CaptureStep.processing;
      _processingFailed = saved.status == DreamStatus.failed;
      _processingFailureCode = _processingFailed ? 'job_failed' : null;
      _engineIdempotencyKey = saved.id;
      _draftReady = true;
      if (_step == CaptureStep.processing) {
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
    _controller.dispose();
    _editorFocus.dispose();
    super.dispose();
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
        final resume = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: context.raised,
              title: const Text('쓰던 꿈이 남아 있어요'),
              content: const Text('남겨 둔 기억을 이어서 적을까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('새로 쓰기'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('이어서 쓰기'),
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
        if (resume == false) {
          await _discardDraft();
          return;
        }
      }
      if (mounted) setState(() => _draftReady = true);
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

  Future<void> _toggleRecording() async {
    if (_recording) {
      _stopRecording();
      return;
    }
    final session = ++_speechSession;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
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
          if (text != null && text.isNotEmpty) {
            _usedVoice = true;
            _voiceHasText = true;
            _controller.text =
                '${_voicePrefix.isEmpty ? '' : '$_voicePrefix\n'}$text';
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
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
    // A bottom snackbar covered the save action when the native keyboard
    // appeared after denied/unavailable speech. Keep guidance in the static
    // prompt slot; the keyboard editor and save row retain their full space.
    setState(() => _voiceNotice = message);
  }

  void _onEditorValueChanged() {
    // Observe the source of truth, including accessibility/autofill/controller
    // updates. onChanged alone does not cover every editing path. Selection
    // and composing-range-only changes must not schedule storage work.
    if (!_draftReady || _submitting || _step != CaptureStep.capture) return;
    final text = _controller.text;
    if (text == _lastDraftText) return;
    _lastDraftText = text;
    _autosave.changed(_snapshot(), immediate: _recording);
  }

  void _onEditorFocus() {
    // Manual editing owns the draft from this point. A late speech partial
    // must not replace the user's newly typed text with the old prefix.
    if (_editorFocus.hasFocus && _recording) _stopRecording();
  }

  Future<void> _saveDream() async {
    if (!_draftReady || _submitting) return;
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장면 하나만 적어도 괜찮아요.'),
          backgroundColor: MongColor.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _stopRecording();
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    final draft = _snapshot();
    try {
      final dreamId = await _autosave.submit(draft);
      AppLog.event('dream_saved', {
        'dream_id': dreamId,
        'mode': draft.inputMode.databaseValue,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _dreamId = dreamId;
        _step = CaptureStep.saved;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('꿈을 저장하지 못했어요. 다시 시도해 주세요.'),
          backgroundColor: MongColor.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startProcessing({bool skip = false}) async {
    if (_submittingGeneration ||
        (_step == CaptureStep.processing && !_processingFailed)) {
      return;
    }
    final dreamId = _dreamId;
    if (dreamId == null) {
      return;
    }
    final retrying = _processingFailureCode == 'job_failed';
    _retryRequestPending = retrying;
    _submittingGeneration = true;
    setState(() {
      _step = CaptureStep.processing;
      _processingStage = 0;
      _jobDone = false;
      _processingFailed = false;
      _processingFailureCode = null;
      _connectionInterrupted = false;
      _submissionUncertain = false;
    });
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
      // A dream UUID is also a valid stable server idempotency key. Reusing it
      // lets foreground submission and a later Outbox retry converge.
      _engineIdempotencyKey ??= dreamId;
      if (retrying) {
        await engine.retry(dreamId);
        // Do not revive the old failed stream before a retry is accepted.
        // Persist even when this route closed during the request; shell
        // recovery owns observation from this point onward.
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
          _step = CaptureStep.saved;
          _processingFailed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('원고 설정을 동기화한 뒤 장면을 만들 수 있어요. 설정에서 반영 상태를 확인해 주세요.'),
          ),
        );
      }
      return;
    } on TrialLimitException catch (error) {
      if (!mounted) return;
      _failProcessing(error.code);
      return;
    } on Object {
      if (!mounted) {
        return;
      }
      _observeProcessing();
      setState(() {
        _connectionInterrupted = true;
        _submissionUncertain = true;
      });
      return;
    } finally {
      _submittingGeneration = false;
    }

    if (!mounted || _step != CaptureStep.processing) {
      return;
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
        // A dropped stream or failed download says nothing about server failure.
        setState(() => _connectionInterrupted = true);
      } else if (next.hasValue) {
        _onJobProgress(next.value);
      }
    }, fireImmediately: true);
  }

  void _reconnectProcessing() {
    final dreamId = _dreamId;
    if (dreamId == null) return;
    // Download/observation only: never insert a job because its stream failed.
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
  }

  void _onJobProgress(JobProgress? progress) {
    if (!mounted || progress == null) {
      return;
    }
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
      setState(() => _step = CaptureStep.archived);
      return;
    }
    setState(
      () => _processingStage = switch (progress.type) {
        JobType.extract => 0,
        JobType.link => 1,
        JobType.plan || JobType.write || JobType.linkPatch => 2,
        JobType.validate || JobType.commit || JobType.remember => 3,
      },
    );
    if (progress.status == JobStatus.done &&
        (progress.type == JobType.commit ||
            progress.type == JobType.remember)) {
      _jobDone = true;
      if (mounted) {
        setState(() {});
      }
      _finishProcessingIfReady();
    }
  }

  void _prepareRevealData() {
    final dreamId = _dreamId;
    if (dreamId == null ||
        !_jobDone ||
        _step == CaptureStep.archived ||
        _revealScene != null ||
        _revealScheduled) {
      return;
    }
    final volume = ref.watch(activeVolumeProvider).value;
    if (volume == null) {
      return;
    }
    final dreams = ref.watch(dreamsProvider(DreamStatusFilter.all)).value;
    final dream = dreams?.where((item) => item.id == dreamId).firstOrNull;
    if (dream?.status == DreamStatus.archivedOnly) {
      if (!_archiveScheduled) {
        _archiveScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _archiveScheduled = false;
          if (!mounted || !_jobDone) return;
          AppLog.event('dream_archived_only', {'dream_id': dreamId});
          setState(() => _step = CaptureStep.archived);
        });
      }
      return;
    }
    final scenes = ref.watch(scenesProvider(volume.id)).value;
    if (scenes == null) {
      return;
    }
    Scene? revealScene;
    for (final scene in scenes.reversed) {
      if (scene.sourceDreamIds.contains(dreamId)) {
        revealScene = scene;
        break;
      }
    }
    if (revealScene == null) {
      return;
    }
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
      if (!mounted) {
        return;
      }
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
        _step == CaptureStep.reveal ||
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
      if (!_canPresent) return;
      var freshGrowth = false;
      final growthId = _revealGrowthEventId;
      if (fresh && growthId != null) {
        freshGrowth = await ref
            .read(repositoryProvider)
            .consumePresentation(
              volumeId: scene.volumeId,
              kind: PresentationKind.growth,
              sourceId: growthId,
            );
      }
      if (!_canPresent) return;
      setState(() {
        _freshReveal = fresh && !retry;
        _freshGrowth = freshGrowth && !retry;
        _presentationError = false;
        _step = CaptureStep.reveal;
      });
      if (_freshReveal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_canPresent || _step != CaptureStep.reveal) return;
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
          // The manuscript is ready even if this device cannot save a UI receipt.
          // Never regenerate it or block access to the actual Reader.
          _freshReveal = false;
          _presentationError = true;
          _step = CaptureStep.reveal;
        });
      }
    } finally {
      if (mounted) setState(() => _revealClaimBusy = false);
    }
  }

  String get _title => switch (_step) {
    CaptureStep.capture => '꿈 기록',
    CaptureStep.saved => '저장 완료',
    CaptureStep.recall => '기억 보강',
    CaptureStep.processing => '',
    CaptureStep.reveal => _freshReveal ? '새 장면' : '저장된 장면',
    CaptureStep.archived => '보관함에 저장됨',
  };

  @override
  Widget build(BuildContext context) {
    _prepareRevealData();
    _finishProcessingIfReady();
    final night = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: _step == CaptureStep.capture,
      body: Stack(
        children: [
          if (_step != CaptureStep.processing &&
              (_step != CaptureStep.capture ||
                  MediaQuery.viewInsetsOf(context).bottom == 0))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _step == CaptureStep.processing
                  ? MediaQuery.sizeOf(context).height * .72
                  : 220,
              child: DreamAtmosphere(
                animate: false,
                night: night,
                strength: _step == CaptureStep.processing ? .22 : .12,
              ),
            ),
          SafeArea(
            key: const ValueKey('capture-safe-content'),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    _FlowHeader(
                      title: _title,
                      dreamNumber: widget.dreamNumber,
                      onClose: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: AnimatedSwitcher(
                        // Fading-out controls must not receive a second tap or
                        // remain exposed to assistive navigation.
                        layoutBuilder: (current, outgoing) => Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final child in outgoing)
                              IgnorePointer(
                                child: ExcludeSemantics(child: child),
                              ),
                            ?current,
                          ],
                        ),
                        duration:
                            MediaQuery.disableAnimationsOf(context) ||
                                _step == CaptureStep.capture ||
                                (_step == CaptureStep.reveal && !_freshReveal)
                            ? Duration.zero
                            : const Duration(milliseconds: 360),
                        switchInCurve: MongMotion.enter,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .025),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: switch (_step) {
                          CaptureStep.capture => _buildCapture(),
                          CaptureStep.saved => _buildSaved(),
                          CaptureStep.recall => _buildRecall(),
                          CaptureStep.processing => _buildProcessing(),
                          CaptureStep.reveal => _buildReveal(),
                          CaptureStep.archived => _buildArchived(),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapture() {
    if (!_draftReady) {
      final failed = _draftLoadFailed || _draftDiscardFailed;
      return MongFlowPage(
        key: const ValueKey('capture-draft-loading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!failed) const ThinkingOrb(state: DreamOrbState.gathering),
            Text(
              failed ? '쓰던 꿈을 안전하게 열지 못했어요' : '쓰던 꿈을 확인하고 있어요',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (failed) ...[
              const SizedBox(height: 12),
              Text(
                '기존 기록은 지우지 않았어요. 다시 확인하거나 닫은 뒤 돌아와 주세요.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: failed
            ? MongActionGroup(
                primary: EditorialButton(
                  label: '다시 확인하기',
                  onPressed: _draftDiscardFailed
                      ? _discardDraft
                      : _restoreDraft,
                ),
              )
            : const SizedBox.shrink(),
      );
    }
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final night = Theme.of(context).brightness == Brightness.dark;
    return AbsorbPointer(
      key: const ValueKey('capture'),
      absorbing: !_draftReady || _submitting,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, keyboardOpen ? 12 : 28, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Keep sibling slots stable during the keyboard's inset animation.
            // Removing the web-help row plus this prompt used to unmount the
            // unkeyed Expanded/EditableText and close Safari's new IME session.
            if (!keyboardOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _voiceNotice ?? '장면 하나만 기억나도 괜찮아요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            Expanded(
              key: const ValueKey('capture-editor-slot'),
              child: RepaintBoundary(
                child: TextField(
                  key: const ValueKey('dream-editor'),
                  focusNode: _editorFocus,
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  enableIMEPersonalizedLearning: false,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.65),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: night
                        ? const Color(0xFF0B1525)
                        : const Color(0xFFF8FCFE),
                    hintText: kIsWeb
                        ? '기억나는 순서대로 적어보세요…'
                        : '기억나는 순서대로 말하거나 적어보세요…',
                    hintStyle: TextStyle(
                      color: night ? MongColor.nightMeta : MongColor.ink3,
                    ),
                    contentPadding: const EdgeInsets.all(MongSpace.lg),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(MongRadius.field),
                      ),
                      borderSide: BorderSide(
                        color: night
                            ? const Color(0xFF24344B)
                            : MongColor.paperShade,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(MongRadius.field),
                      ),
                      borderSide: BorderSide(
                        color: night ? MongColor.nightSky : MongColor.sky300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              key: const ValueKey('capture-autosave-status'),
              valueListenable: _autosave.saveFailed,
              builder: (context, failed, _) => failed
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          '자동 저장하지 못했어요. 이 화면을 닫지 말고 내용을 복사해 주세요.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (kIsWeb && !keyboardOpen)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: MetaText('녹음은 iPhone 앱 전용 · 마이크를 누르면 안내해요'),
              ),
            Row(
              key: const ValueKey('capture-actions'),
              children: [
                if (kIsWeb && !keyboardOpen) ...[
                  IconButton.outlined(
                    tooltip: '음성 입력 안내 · iPhone 앱 전용 녹음',
                    onPressed: () => Navigator.of(
                      context,
                    ).push(quietPageRoute(const WebVoiceGuide())),
                    icon: const Icon(Icons.mic_none),
                    constraints: const BoxConstraints.tightFor(
                      width: 52,
                      height: 52,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (!kIsWeb && (!keyboardOpen || _recording)) ...[
                  Semantics(
                    button: true,
                    label: _recording ? '녹음 멈추기' : '녹음 시작',
                    child: InkWell(
                      onHighlightChanged: (pressed) {
                        if (_recordButtonPressed == pressed) return;
                        setState(() => _recordButtonPressed = pressed);
                      },
                      onTap: _toggleRecording,
                      customBorder: const CircleBorder(),
                      child: AnimatedScale(
                        scale: _recordButtonPressed ? .94 : 1,
                        duration: MongMotion.micro,
                        curve: MongMotion.enter,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _recording
                                ? MongColor.dreamBlueDeep
                                : night
                                ? const Color(0xFF0B1525)
                                : Colors.white,
                            border: Border.all(color: MongColor.sky300),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _recording ? Icons.stop_rounded : Icons.mic_none,
                            size: 24,
                            color: _recording || night
                                ? Colors.white
                                : MongColor.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  key: const ValueKey('capture-save-action'),
                  child: EditorialButton(
                    label: '꿈 저장하기',
                    onPressed: _saveDream,
                  ),
                ),
              ],
            ),
            if (_recording) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: MetaText('녹음 중     한 번 더 누르면 멈춰요'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecall() {
    const questions = [
      ('light', '밝았나요, 어두웠나요?', ['밝음', '어두움', '모름']),
      ('company', '누군가 함께 있었나요?', ['혼자', '아는 사람', '모르는 사람', '모름']),
      ('feeling', '가장 강했던 감정은?', ['불안', '그리움', '설렘', '두려움', '평온', '모름']),
    ];
    return SingleChildScrollView(
      key: const ValueKey('recall'),
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Text('꿈이 저장됐어요', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '기억의 빈자리만\n조금 더 확인할게요.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '생각나지 않으면 모름을 골라도 돼요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? MongColor.nightMeta
                  : MongColor.ink2,
            ),
          ),
          const SizedBox(height: 36),
          for (final question in questions) ...[
            Text(question.$2, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final answer in question.$3)
                  ChoiceChipEditorial(
                    label: answer,
                    selected: _answers[question.$1] == answer,
                    onTap: () => setState(() => _answers[question.$1] = answer),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
          ],
          EditorialButton(
            label: _savingRecall ? '기억 저장 중' : '보강 마치기',
            onPressed: _savingRecall ? null : _finishRecall,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: _savingRecall ? null : () => _finishRecall(skip: true),
              child: const Text('전체 건너뛰기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaved() => MongFlowPage(
    key: const ValueKey('saved'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MemoryStamp(),
        const SizedBox(height: MongSpace.md),
        Semantics(
          liveRegion: true,
          child: Text(
            '꿈이 저장됐어요',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        const SizedBox(height: MongSpace.md),
        Text(
          '떠오른 만큼 남겼다면 충분해요.\n지금 이야기로 만들지 않아도 괜찮아요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
        ),
        if (_answers.isNotEmpty) ...[
          const SizedBox(height: MongSpace.md),
          const MetaText('보강한 기억도 함께 사용할게요.'),
        ],
      ],
    ),
    actions: MongActionGroup(
      primary: GlassActionButton(
        label: '장면 만들기',
        onPressed: () => _startProcessing(skip: _answers.isEmpty),
      ),
      secondary: [
        TextButton(
          onPressed: () => setState(() => _step = CaptureStep.recall),
          child: const Text('기억 더 보강하기'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('나중에 만들기'),
        ),
      ],
    ),
  );

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
          _step = CaptureStep.saved;
        });
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보강한 기억을 저장하지 못했어요. 답변은 그대로 남아 있어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingRecall = false);
    }
  }

  Widget _buildProcessing() {
    if (_processingFailed) {
      final trialLimit =
          _processingFailureCode == 'trial_user_daily_limit' ||
          _processingFailureCode == 'trial_global_daily_limit';
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trialLimit ? '오늘의 체험 횟수를 모두 사용했어요.' : '장면을 만들지 못했어요.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('꿈은 보관함에 저장되어 있어요.'),
            const SizedBox(height: 28),
            if (!trialLimit)
              EditorialButton(label: '다시 시도', onPressed: _startProcessing),
            TextButton(
              child: const Text('보관함에서 나중에 보기'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    return Center(
      key: const ValueKey('processing'),
      child: Semantics(
        liveRegion: true,
        label: '소설을 만들고 있어요',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    MongColor.sky500.withValues(alpha: .12),
                    MongColor.sky500.withValues(alpha: 0),
                  ],
                ),
              ),
              child: SizedBox.square(
                dimension: 120,
                child: Center(
                  child: ThinkingOrb(
                    state: switch (_processingStage) {
                      0 => DreamOrbState.gathering,
                      1 => DreamOrbState.connecting,
                      2 => DreamOrbState.composing,
                      _ => DreamOrbState.checking,
                    },
                    color: Theme.of(context).brightness == Brightness.dark
                        ? MongColor.nightSky
                        : MongColor.orbInk,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _connectionInterrupted ? '연결을 확인하고 있어요' : '소설을 만들고 있어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_connectionInterrupted) ...[
              const SizedBox(height: 12),
              const Text('생성 결과를 다시 확인해요. 새로 만들지 않아요.'),
              TextButton(
                onPressed: _reconnectProcessing,
                child: const Text('상태 다시 확인'),
              ),
              if (_submissionUncertain)
                TextButton(
                  onPressed: _confirmSubmission,
                  child: const Text('접수 다시 확인'),
                ),
            ],
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('나중에 확인하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReveal() {
    final scene = _revealScene!;
    final first = _revealPassages.firstOrNull;
    final scenes = ref.watch(scenesProvider(scene.volumeId)).value;
    // Derive this from committed local content, never from a route counter.
    final isFirstScene = scenes?.length == 1 && scenes!.single.id == scene.id;
    return MongFlowPage(
      key: const ValueKey('reveal'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            liveRegion: true,
            child: MetaText(
              !_freshReveal
                  ? '원고에 보관된 장면이에요.'
                  : isFirstScene
                  ? '내 꿈에서 시작한 첫 장면이에요.'
                  : '꿈이 한 장면이 되었어요.',
            ),
          ),
          const SizedBox(height: MongSpace.xs),
          Row(
            children: [
              Expanded(
                child: MetaText(
                  'DREAM ${widget.dreamNumber.toString().padLeft(3, '0')}  →  SCENE ${widget.sceneNumber}',
                ),
              ),
              if (!isFirstScene && _freshReveal && _freshGrowth)
                MetaText(
                  '${_revealDeltaPercent >= 0 ? '+' : ''}$_revealDeltaPercent%',
                ),
            ],
          ),
          const SizedBox(height: MongSpace.lg),
          Text(
            scene.title ?? '제목 없는 장면',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: MongSpace.md),
          if (first != null)
            Text(
              first.text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: MongSpace.xs),
          MetaText(
            first?.origin == PassageOrigin.dream ? '꿈에서 온 첫 문장' : '원고의 첫 문장',
          ),
          if (isFirstScene) ...[
            const SizedBox(height: MongSpace.md),
            Text(
              '먼저 천천히 읽어보세요.\n꿈 원문은 보관함에 따로 남아 있어요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
          ],
          if (_presentationError) ...[
            const SizedBox(height: MongSpace.md),
            Text(
              '화면 상태를 저장하지 못했어요. 장면은 그대로 읽을 수 있어요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
          ],
        ],
      ),
      actions: MongActionGroup(
        primary: GlassActionButton(
          label: _freshReveal ? '새 장면 읽기' : '장면 읽기',
          onPressed: () => Navigator.of(context).pushReplacement<bool, bool>(
            quietPageRoute(
              ReaderScreen(volumeId: scene.volumeId, initialSceneId: scene.id),
            ),
            result: true,
          ),
        ),
        secondary: [
          if (_presentationError)
            TextButton(
              onPressed: _revealClaimBusy
                  ? null
                  : () => _consumeReveal(retry: true),
              child: const Text('화면 상태 다시 저장'),
            ),
          TextButton(
            onPressed: _showDirectionSheet,
            child: const Text('장면 조정하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectionSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? MongColor.nightShade
        : MongColor.paper,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MongSheetHandle(),
              const SizedBox(height: 24),
              Text(
                '장면을 조정하기',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_revealDecision != null) ...[
                const SizedBox(height: 24),
                Text(
                  '오늘의 ‘${_revealDecision!.payload['label'] ?? '기억 속 존재'}’,\n'
                  '${_revealDecision!.payload['candidate_label'] ?? '앞 장면의 존재'}일까요?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in const ['같은 사람', '다른 사람', '모르겠음'])
                      ChoiceChipEditorial(
                        label: choice,
                        selected: _linkChoice == choice,
                        onTap: _savingLink
                            ? () {}
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
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showPlacementSheet();
                },
                child: const Text('장면의 위치 바꾸기'),
              ),
              const SizedBox(height: 12),
              GlassActionButton(
                label: '완료',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildArchived() {
    return Padding(
      key: const ValueKey('archived'),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetaText('DREAM ARCHIVE'),
          const Spacer(),
          Text(
            '이번 꿈은 아직\n원고와 이어지지 않았어요.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 18),
          Text(
            '원문은 보관함에 안전하게 남겨두었습니다.\n다음 꿈이 새로운 연결을 만들 수 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
          ),
          const Spacer(),
          EditorialButton(
            label: '원고로 돌아가기',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('연결 선택을 저장하지 못했어요.')));
      }
    } finally {
      if (mounted) setState(() => _savingLink = false);
    }
  }

  void _showPlacementSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? MongColor.nightShade
          : MongColor.paper,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MongSheetHandle(),
              const SizedBox(height: 26),
              Text(
                '이 장면을 어디에 둘까요?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('사이 장면으로 넣기'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () async {
                  await ref
                      .read(repositoryProvider)
                      .changePlacement(
                        _revealScene!.id,
                        PlacementKind.interlude,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('원고에서 빼기'),
                subtitle: const Text('꿈은 보관함에 그대로 남아요.'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () async {
                  final dreamId = _dreamId;
                  if (dreamId != null) {
                    await ref
                        .read(repositoryProvider)
                        .removeDreamFromManuscript(dreamId);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.dreamNumber,
    required this.onClose,
  });

  final String title;
  final int dreamNumber;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: MetaText(
              'DREAM ${dreamNumber.toString().padLeft(3, '0')}     $title',
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20),
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }
}

DateTime _dreamDate(DateTime now) {
  final adjusted = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
  return DateTime(adjusted.year, adjusted.month, adjusted.day);
}

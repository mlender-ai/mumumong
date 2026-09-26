import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dot_field.dart';
import '../../core/log/app_log.dart';
import '../../data/speech/speech_input.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import 'draft_autosave.dart';

enum CaptureStep { capture, recall, processing, reveal, archived }

class CaptureFlow extends ConsumerStatefulWidget {
  const CaptureFlow({
    super.key,
    required this.dreamNumber,
    required this.sceneNumber,
  });

  final int dreamNumber;
  final int sceneNumber;

  @override
  ConsumerState<CaptureFlow> createState() => _CaptureFlowState();
}

class _CaptureFlowState extends ConsumerState<CaptureFlow>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _controller = TextEditingController();
  late final AnimationController _motion;
  CaptureStep _step = CaptureStep.capture;
  bool _recording = false;
  int _dotCount = 20;
  late final SpeechInput _speech;
  StreamSubscription<SpeechUpdate>? _speechSubscription;
  String _voicePrefix = '';
  bool _voiceHasText = false;
  bool _speechGuidanceShown = false;
  Timer? _slowTimer;
  bool _slowProcessing = false;
  bool _processingFailed = false;
  StreamSubscription<JobProgress?>? _jobSubscription;
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
  bool _archiveScheduled = false;
  String? _engineIdempotencyKey;
  late final DraftAutosave _autosave;
  DreamDraft? _draft;
  bool _draftReady = false;
  bool _submitting = false;
  Timer? _restoreRetry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autosave = DraftAutosave(ref.read(repositoryProvider));
    _speech = ref.read(speechInputProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreRetry?.cancel();
    _autosave.dispose();
    unawaited(_speechSubscription?.cancel());
    unawaited(_speech.stop());
    _slowTimer?.cancel();
    _jobSubscription?.cancel();
    _motion.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopRecording();
    }
    if (state != AppLifecycleState.resumed) unawaited(_autosave.flush());
  }

  Future<void> _restoreDraft() async {
    if (!mounted) return;
    try {
      final draft = await _autosave.repository.loadDraft();
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
              backgroundColor: MongColor.paper,
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
      if (mounted) {
        _restoreRetry = Timer(const Duration(seconds: 1), _restoreDraft);
      }
    }
  }

  Future<void> _discardDraft() async {
    try {
      await _autosave.discard();
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _draft = null;
        _usedVoice = false;
        _dotCount = 20;
        _draftReady = true;
      });
    } on Object {
      if (mounted) {
        _restoreRetry = Timer(const Duration(seconds: 1), _discardDraft);
      }
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
    HapticFeedback.selectionClick();
    setState(() {
      _recording = true;
      _voiceHasText = false;
      _voicePrefix = _controller.text.trimRight();
    });
    await _speechSubscription?.cancel();
    try {
      _speechSubscription = _speech.updates.listen((update) {
        if (!mounted || !_recording) return;
        final text = update.text;
        if (text != null && text.isNotEmpty) {
          _usedVoice = true;
          _voiceHasText = true;
          _controller.text =
              '${_voicePrefix.isEmpty ? '' : '$_voicePrefix\n'}$text';
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
          _autosave.changed(_snapshot(), immediate: true);
        }
        setState(
          () => _dotCount = (20 + update.rms * 500).round().clamp(20, 300),
        );
        if (update.code != null) _speechFailed();
        if (update.stopped) {
          _stopRecording();
          if (!_voiceHasText) _speechMessage('들리지 않았어요. 직접 적어보시겠어요?');
        }
      }, onError: (Object _) => _speechFailed());
      await _speech.start();
    } on Object {
      _speechFailed();
    }
  }

  void _stopRecording() {
    unawaited(_speech.stop());
    if (mounted) setState(() => _recording = false);
  }

  void _speechFailed() {
    if (!mounted || !_recording) return;
    _stopRecording();
    if (_speechGuidanceShown) return;
    _speechGuidanceShown = true;
    _speechMessage(
      '이 기기에서 음성 인식을 사용할 수 없어요. 직접 적어주세요. iPhone 설정에서 마이크와 음성 인식 권한을 확인할 수 있어요.',
    );
  }

  void _speechMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTextChanged(String value) {
    _autosave.changed(_snapshot());
    final words = value.trim().isEmpty
        ? 0
        : value.trim().split(RegExp(r'\s+')).length;
    setState(() => _dotCount = (20 + words).clamp(20, 300));
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
        _step = CaptureStep.recall;
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
    if (_step == CaptureStep.processing && !_processingFailed) return;
    final dreamId = _dreamId;
    if (dreamId == null) {
      return;
    }
    setState(() {
      _step = CaptureStep.processing;
      _processingStage = 0;
      _jobDone = false;
      _processingFailed = false;
      _slowProcessing = false;
    });
    _slowTimer?.cancel();
    _motion.duration = const Duration(seconds: 8);
    _motion.repeat();
    _slowTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && _step == CaptureStep.processing) {
        setState(() => _slowProcessing = true);
        _motion.duration = const Duration(seconds: 16);
        _motion.repeat();
      }
    });
    await _jobSubscription?.cancel();
    final engine = ref.read(engineClientProvider);
    try {
      await ref
          .read(repositoryProvider)
          .answerRecall(dreamId, skip ? {} : _answers);
      AppLog.event(skip ? 'recall_skipped' : 'recall_answered', {
        'dream_id': dreamId,
      });
      // A dream UUID is also a valid stable server idempotency key. Reusing it
      // lets foreground submission and a later Outbox retry converge.
      _engineIdempotencyKey ??= dreamId;
      await engine.enqueue(dreamId, _engineIdempotencyKey!);
      if (!mounted) return;
      _jobSubscription = engine
          .watch(dreamId)
          .listen(
            _onJobProgress,
            onError: (Object _) => _failProcessing('stream_unavailable'),
          );
    } on Object {
      if (!mounted) {
        return;
      }
      _failProcessing('enqueue_unavailable');
      return;
    }

    if (!mounted || _step != CaptureStep.processing) {
      return;
    }
  }

  void _failProcessing(String code) {
    if (!mounted || _processingFailed) return;
    _slowTimer?.cancel();
    AppLog.event('processing_failed', {
      'stage': _processingStage,
      'code': code,
    });
    setState(() => _processingFailed = true);
  }

  void _onJobProgress(JobProgress? progress) {
    if (!mounted || progress == null) {
      return;
    }
    if (progress.status == JobStatus.failed) {
      _failProcessing('job_failed');
      return;
    }
    if (progress.status == JobStatus.done && progress.archivedOnly) {
      _slowTimer?.cancel();
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
    if (passages == null || progressEvents == null || decisions == null) {
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
        _processingFailed ||
        !_jobDone ||
        _processingStage < 3 ||
        _revealScene == null) {
      return;
    }
    _slowTimer?.cancel();
    AppLog.event('processing_completed', {'dream_id': _dreamId});
    AppLog.event('reveal_viewed', {
      'dream_id': _dreamId,
      'scene_id': _revealScene!.id,
    });
    setState(() => _step = CaptureStep.reveal);
  }

  String get _title => switch (_step) {
    CaptureStep.capture => '꿈 기록',
    CaptureStep.recall => '기억 보강',
    CaptureStep.processing => '장면을 만드는 중',
    CaptureStep.reveal => '새 장면',
    CaptureStep.archived => '보관함에 저장됨',
  };

  @override
  Widget build(BuildContext context) {
    _prepareRevealData();
    return Scaffold(
      resizeToAvoidBottomInset: _step == CaptureStep.capture,
      body: SafeArea(
        child: Column(
          children: [
            _FlowHeader(
              title: _title,
              dreamNumber: widget.dreamNumber,
              onClose: () => Navigator.pop(context),
            ),
            const Divider(),
            Expanded(
              child: AnimatedSwitcher(
                duration: MongMotion.page,
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
    );
  }

  Widget _buildCapture() {
    return AbsorbPointer(
      absorbing: !_draftReady || _submitting,
      child: Padding(
        key: const ValueKey('capture'),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '장면 하나만 기억나도 괜찮아요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 5,
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 17),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: MongColor.paperShade,
                  hintText: '기억나는 순서대로 말하거나 적어보세요…',
                  hintStyle: TextStyle(
                    color: MongColor.ink3,
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                  ),
                  contentPadding: EdgeInsets.all(18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: MongColor.sky700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 3,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) => MemoryParticles(
                    count: _dotCount,
                    progress: _motion.value,
                    color: MongColor.ink.withValues(alpha: .74),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: _recording ? '녹음 멈추기' : '녹음 시작',
                  child: InkWell(
                    onTap: _toggleRecording,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _recording ? MongColor.ink : MongColor.paper,
                        border: Border.all(color: MongColor.ink),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: MongMotion.micro,
                        width: _recording ? 10 : 12,
                        height: _recording ? 10 : 12,
                        decoration: BoxDecoration(
                          color: _recording ? MongColor.sky500 : MongColor.ink,
                          borderRadius: BorderRadius.circular(
                            _recording ? 1 : 99,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EditorialButton(label: '기록 저장', onPressed: _saveDream),
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
          Text(
            '기억의 빈자리만\n조금 더 확인할게요.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '생각나지 않으면 모름을 골라도 돼요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
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
          EditorialButton(label: '이 기억으로 장면 만들기', onPressed: _startProcessing),
          const SizedBox(height: 4),
          Center(
            child: QuietTextButton(
              label: '전체 건너뛰기',
              onPressed: () => _startProcessing(skip: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    if (_processingFailed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '장면을 만들지 못했어요.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('꿈은 보관함에 저장되어 있어요.'),
            const SizedBox(height: 28),
            EditorialButton(
              label: '다시 시도',
              onPressed: () {
                // User and transport retries converge on the stable dream UUID.
                _engineIdempotencyKey = null;
                _startProcessing();
              },
            ),
            QuietTextButton(
              label: '보관함에서 나중에 보기',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    const labels = ['꿈을 읽는 중', '이어질 곳을 찾는 중', '장면을 쓰는 중', '확인하는 중'];
    return AnimatedBuilder(
      key: const ValueKey('processing'),
      animation: _motion,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetaText(labels[_processingStage]),
              const Spacer(),
              SizedBox(
                height: 310,
                width: double.infinity,
                child: _ProcessingDots(
                  stage: _processingStage,
                  progress: _motion.value,
                ),
              ),
              const Spacer(),
              Text(
                '기억의 조각이 원고의 문장으로\n자리를 찾고 있어요.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              Text(
                _slowProcessing
                    ? '조금 더 시간이 필요해요. 꿈은 안전하게 저장되어 있어요.'
                    : '저장한 기억을 바탕으로 장면을 만들고 있어요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReveal() {
    final scene = _revealScene!;
    return SingleChildScrollView(
      key: const ValueKey('reveal'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetaText(
                'DREAM ${widget.dreamNumber.toString().padLeft(3, '0')}  →  SCENE ${widget.sceneNumber}',
              ),
              MetaText(
                '${_revealDeltaPercent >= 0 ? '+' : ''}$_revealDeltaPercent%',
                color: MongColor.ink,
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            scene.title ?? '제목 없는 장면',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          for (final passage in _revealPassages)
            _NewPassage(text: passage.text),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 24),
          if (_revealDecision != null) ...[
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
                    onTap: _savingLink ? () {} : () => _decideLink(choice),
                  ),
              ],
            ),
            const SizedBox(height: 28),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이어지는 장면으로 넣었어요.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              QuietTextButton(label: '다르게 넣기', onPressed: _showPlacementSheet),
            ],
          ),
          const SizedBox(height: 18),
          EditorialButton(
            label: '원고에서 확인하기',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

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
            ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
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
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 34, height: 2, color: MongColor.line),
              ),
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

class _NewPassage extends StatelessWidget {
  const _NewPassage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 30,
            margin: const EdgeInsets.only(right: 14, top: 7),
            color: MongColor.sky500,
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ProcessingDots extends StatelessWidget {
  const _ProcessingDots({required this.stage, required this.progress});

  final int stage;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (stage == 0) {
      return Stack(
        children: [
          for (var i = 0; i < 6; i++)
            Positioned(
              left:
                  28 + (i % 3) * 92 + 5 * (i.isEven ? progress : 1 - progress),
              top:
                  45 +
                  (i ~/ 3) * 112 +
                  7 * (i.isEven ? 1 - progress : progress),
              child: _DotCluster(seed: i),
            ),
        ],
      );
    }
    if (stage == 1) {
      return Stack(
        children: [
          Positioned(
            right: 8,
            top: 8,
            width: 112,
            child: Opacity(
              opacity: .34,
              child: DotCover(clarity: .28, seed: 14),
            ),
          ),
          for (var i = 0; i < 5; i++)
            Positioned(
              left: 12 + i * 38 + progress * 28,
              top: 82 + i * 34 - progress * 8,
              child: _DotCluster(seed: i, scale: .7),
            ),
        ],
      );
    }
    if (stage == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var row = 0; row < 5; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  for (var dot = 0; dot < 18 - row * 2; dot++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot > 14 - row
                            ? MongColor.sky300
                            : MongColor.ink,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var row = 0; row < 5; row++)
          Container(
            width: 270 - row * 22,
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 13),
            color: MongColor.ink.withValues(alpha: .42 + .25 * progress),
          ),
      ],
    );
  }
}

class _DotCluster extends StatelessWidget {
  const _DotCluster({required this.seed, this.scale = 1});
  final int seed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const points = [
      Offset(5, 9),
      Offset(16, 2),
      Offset(28, 8),
      Offset(9, 20),
      Offset(22, 18),
      Offset(34, 23),
      Offset(17, 31),
    ];
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 40,
        height: 38,
        child: Stack(
          children: [
            for (var i = 0; i < points.length; i++)
              Positioned(
                left: points[(i + seed) % points.length].dx,
                top: points[(i + seed) % points.length].dy,
                child: Container(
                  width: i.isEven ? 5 : 3,
                  height: i.isEven ? 5 : 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 1 ? MongColor.sky500 : MongColor.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

DateTime _dreamDate(DateTime now) {
  final adjusted = now.hour < 4 ? now.subtract(const Duration(days: 1)) : now;
  return DateTime(adjusted.year, adjusted.month, adjusted.day);
}

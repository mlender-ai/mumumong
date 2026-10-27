// V2 first-manuscript setup. Same contract as V1 VolumeSetupScreen: the
// default path creates the volume through CloudSyncService; the preview
// injects the in-memory adapter through v2CreateVolumeProvider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/progress.dart';
import '../design/atmosphere.dart';
import '../design/halftone.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'v2_providers.dart';

class V2VolumeSetupScreen extends ConsumerStatefulWidget {
  const V2VolumeSetupScreen({
    super.key,
    required this.onComplete,
    this.createVolume,
  });

  final VoidCallback onComplete;
  final V2CreateVolume? createVolume;

  @override
  ConsumerState<V2VolumeSetupScreen> createState() =>
      _V2VolumeSetupScreenState();
}

class _V2VolumeSetupScreenState extends ConsumerState<V2VolumeSetupScreen> {
  AdaptationLevel _adaptation = AdaptationLevel.balanced;
  WritingStyle _style = WritingStyle.plain;
  NarrativeVoice _voice = NarrativeVoice.firstPersonPast;
  bool _saving = false;
  bool _failed = false;
  bool _details = false;

  Future<void> _start() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final create =
          widget.createVolume ??
          ref.read(v2CreateVolumeProvider) ??
          ref.read(cloudSyncServiceProvider).createVolume;
      await create(
        adaptation: _adaptation,
        style: _style,
        narrativeVoice: _voice,
      );
      if (mounted) widget.onComplete();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return V2Page(
      mood: V2Mood.home,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                V2Space.gutter,
                V2Space.xl,
                V2Space.gutter,
                V2Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: 168,
                      child: V2Surface(
                        kind: V2SurfaceKind.paper,
                        radius: V2Radius.card - 4,
                        padding: const EdgeInsets.all(18),
                        child: V2Manuscript(
                          motif: V2Motif.door,
                          seed: 7,
                          progress: 0,
                          assemble: true,
                          columns: 22,
                          semanticsLabel: '아직 비어 있는 원고 한 장',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: V2Space.lg),
                  Semantics(
                    header: true,
                    liveRegion: _saving,
                    child: Text(
                      _saving ? '첫 원고를\n준비하고 있어요' : '첫 이야기를\n시작해 볼까요?',
                      style: V2Type.display,
                    ),
                  ),
                  const SizedBox(height: V2Space.xs),
                  const Text('기억나는 장면 하나면 충분해요.', style: V2Type.body),
                  if (_details && !_saving) ...[
                    const SizedBox(height: V2Space.xl),
                    _section('꿈과 이야기의 거리', [
                      for (final option in const [
                        (AdaptationLevel.faithful, '꿈에 충실하게'),
                        (AdaptationLevel.balanced, '균형 있게'),
                      ])
                        V2ChoiceChip(
                          label: option.$2,
                          selected: _adaptation == option.$1,
                          onSelected: () =>
                              setState(() => _adaptation = option.$1),
                        ),
                    ]),
                    _section('문장의 느낌', [
                      for (final option in const [
                        (WritingStyle.plain, '담백하게'),
                        (WritingStyle.lyrical, '서정적으로'),
                        (WritingStyle.cinematic, '영화적으로'),
                      ])
                        V2ChoiceChip(
                          label: option.$2,
                          selected: _style == option.$1,
                          onSelected: () => setState(() => _style = option.$1),
                        ),
                    ]),
                    _section('이야기의 시점', [
                      for (final option in const [
                        (NarrativeVoice.firstPersonPast, '나의 시점'),
                        (NarrativeVoice.thirdPersonPast, '소설 속 인물 시점'),
                      ])
                        V2ChoiceChip(
                          label: option.$2,
                          selected: _voice == option.$1,
                          onSelected: () => setState(() => _voice = option.$1),
                        ),
                    ]),
                  ],
                  const SizedBox(height: V2Space.xl),
                  if (_failed) ...[
                    const V2Notice(
                      message: '원고를 만들지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
                    ),
                    const SizedBox(height: V2Space.md),
                  ],
                  V2ActionStack(
                    primary: V2Button(
                      label: '시작하기',
                      expand: true,
                      loading: _saving,
                      loadingLabel: '준비하는 중',
                      onPressed: _start,
                    ),
                    secondary: [
                      if (!_saving)
                        V2TextAction(
                          label: _details ? '이야기 설정 접기' : '이야기 설정',
                          onPressed: () => setState(() => _details = !_details),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> choices) => Padding(
    padding: const EdgeInsets.only(bottom: V2Space.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: V2Type.headline),
        const SizedBox(height: V2Space.sm),
        Wrap(spacing: 8, runSpacing: 8, children: choices),
      ],
    ),
  );
}

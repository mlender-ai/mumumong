import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import 'settings_components.dart';

/// Author preferences only. Saving never starts generation or rewrites passages.
class GenerationSettingsScreen extends ConsumerStatefulWidget {
  const GenerationSettingsScreen({super.key});

  @override
  ConsumerState<GenerationSettingsScreen> createState() =>
      _GenerationSettingsScreenState();
}

class _GenerationSettingsScreenState
    extends ConsumerState<GenerationSettingsScreen> {
  GenerationSettings? _draft;
  bool _saving = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) setState(() => _draft = null);
    } on Object {
      if (mounted) {
        setState(() => _error = '저장하지 못했어요. 선택은 유지했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(activeVolumeProvider);
    final content = volume.when(
      loading: () => const Center(child: Text('설정을 불러오는 중이에요.')),
      error: (_, _) => const Center(child: Text('원고 설정을 불러오지 못했어요.')),
      data: (value) => value == null
          ? const Center(child: Text('첫 원고를 시작한 뒤 설정할 수 있어요.'))
          : ref
                .watch(generationSettingsProvider(value.id))
                .when(
                  loading: () => const Center(child: Text('설정을 불러오는 중이에요.')),
                  error: (_, _) => const Center(child: Text('설정을 불러오지 못했어요.')),
                  data: (state) => state == null
                      ? const Center(child: Text('설정할 원고가 없어요.'))
                      : _editor(value, state),
                ),
    );
    return SettingsDetailFrame(
      title: '이후 장면 설정',
      description: '저장 후 시작하는 생성부터 적용돼요. 기존 원고와 내가 쓴 문장은 그대로예요.',
      onBack: () => Navigator.pop(context),
      child: content,
    );
  }

  Widget _editor(Volume volume, GenerationSettingsState state) {
    final selected = _draft ?? state.selected;
    final pending = state.status == SettingsSyncStatus.pending;
    final conflict = state.status == SettingsSyncStatus.conflict;
    final closed = ![
      VolumeStatus.active,
      VolumeStatus.completable,
    ].contains(volume.status);
    final locked = _saving || pending || conflict || closed;
    final repository = ref.read(repositoryProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            children: [
              MetaText('확인된 설정 v${state.version}'),
              const SizedBox(height: 24),
              IgnorePointer(
                ignoring: locked,
                child: Opacity(
                  opacity: locked ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsGroupLabel('각색'),
                      _options(
                        AdaptationLevel.values,
                        selected.adaptation,
                        (item) => setState(
                          () => _draft = GenerationSettings(
                            adaptation: item,
                            style: selected.style,
                            narrativeVoice: selected.narrativeVoice,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SettingsGroupLabel('문체'),
                      _options(
                        WritingStyle.values,
                        selected.style,
                        (item) => setState(
                          () => _draft = GenerationSettings(
                            adaptation: selected.adaptation,
                            style: item,
                            narrativeVoice: selected.narrativeVoice,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SettingsGroupLabel('시점'),
                      _options(
                        NarrativeVoice.values,
                        selected.narrativeVoice,
                        (item) => setState(
                          () => _draft = GenerationSettings(
                            adaptation: selected.adaptation,
                            style: selected.style,
                            narrativeVoice: item,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                closed
                    ? '완결을 시작한 원고의 설정은 바꿀 수 없어요.'
                    : conflict
                    ? '다른 기기에서 설정이 바뀌었어요. 어느 설정을 사용할지 선택해 주세요.'
                    : pending
                    ? '동기화 대기 중이에요. 서버 확인 전에는 새 생성을 시작하지 않아요. 기록과 원고 읽기는 계속할 수 있어요.'
                    : '이미 진행 중인 생성은 시작할 때의 설정을 유지해요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (conflict) ...[
                const SizedBox(height: 16),
                Text('이 기기의 선택: ${_summary(state.selected)}'),
                const SizedBox(height: 8),
                Text('서버의 설정: ${_summary(state.confirmed)}'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, semanticsLabel: _error),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!closed)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: EditorialButton(
                    label: _saving
                        ? '저장 중'
                        : conflict
                        ? '이 기기의 선택 적용'
                        : pending
                        ? '동기화 다시 시도'
                        : '설정 저장',
                    onPressed:
                        _saving ||
                            (!pending &&
                                !conflict &&
                                selected == state.confirmed)
                        ? null
                        : () => _run(
                            () => conflict
                                ? repository.resolveGenerationSettingsConflict(
                                    volume.id,
                                    keepLocal: true,
                                  )
                                : pending
                                ? repository.retryGenerationSettings(volume.id)
                                : repository.saveGenerationSettings(
                                    volume.id,
                                    selected,
                                  ),
                          ),
                  ),
                ),
              if (conflict)
                MongButton.ghost(
                  label: '서버 설정 사용',
                  onPressed: _saving
                      ? null
                      : () => _run(
                          () => repository.resolveGenerationSettingsConflict(
                            volume.id,
                            keepLocal: false,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _options<T extends Enum>(
    List<T> values,
    T selected,
    ValueChanged<T> onSelect,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in values)
        ChoiceChipEditorial(
          label: _label(item),
          selected: item == selected,
          onTap: () => onSelect(item),
        ),
    ],
  );

  String _summary(GenerationSettings value) =>
      '${_label(value.adaptation)} · ${_label(value.style)} · ${_label(value.narrativeVoice)}';

  String _label(Enum value) => switch (value) {
    AdaptationLevel.faithful => '꿈에 충실하게',
    AdaptationLevel.balanced => '균형 있게',
    WritingStyle.plain => '담백하게',
    WritingStyle.lyrical => '서정적으로',
    WritingStyle.cinematic => '영화적으로',
    NarrativeVoice.firstPersonPast => '나의 시점',
    NarrativeVoice.thirdPersonPast => '소설 속 인물 시점',
    _ => throw ArgumentError('unsupported settings option'),
  };
}

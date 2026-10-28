// V2 settings (DESIGN_V2.md §8.8). The same settings V1 offers, drawn with
// V2 rows and pages. Behaviour comes from the shared providers: UiPreferences,
// AppLockController, AiConsentRepository, the repository's generation
// settings and RecordActions. Completed books live in library.dart.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../ui/auth/ai_consent.dart';
import '../../ui/settings/record_actions.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../components/policy_link.dart';
import '../components/rows.dart';
import '../design/atmosphere.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'reading_settings.dart';
import 'library.dart';
import 'v2_providers.dart';

void _open(BuildContext context, Widget page) =>
    Navigator.of(context).push(v2Route(page));

class V2SettingsScreen extends ConsumerWidget {
  const V2SettingsScreen({super.key, this.extras});

  /// Extra rows at the end (the preview's restart action).
  final Widget? extras;

  @override
  Widget build(BuildContext context, WidgetRef ref) => V2SettingsFrame(
    title: '설정',
    description: '읽기, 기록, 앱 보호 방식을 정해요.',
    backLabel: '원고로 돌아가기',
    children: [
      const V2GroupLabel('나에게 맞게'),
      V2ListRow(
        title: '읽기와 종이',
        subtitle: '종이 · 글자 크기 · 문장의 출처',
        onTap: () => _open(context, const V2ReadingSettingsPage()),
      ),
      const V2GroupLabel('내 기록'),
      V2ListRow(
        title: '내가 완성한 책',
        subtitle: '완성본 읽기 · PDF 저장 · 다음 권',
        onTap: () => _open(context, const V2LibraryScreen()),
      ),
      V2ListRow(
        title: '이후 장면 설정',
        subtitle: '각색 · 문체 · 시점 · 기존 원고는 그대로',
        onTap: () => _open(context, const V2GenerationSettingsPage()),
      ),
      V2ListRow(
        title: '기록 관리',
        subtitle: 'JSON 사본과 삭제 · PDF는 완성본에서',
        onTap: () => _open(context, const V2RecordsPage()),
      ),
      const V2GroupLabel('보안'),
      V2ListRow(
        title: '앱 잠금',
        subtitle: 'Face ID 또는 기기 암호',
        onTap: () => _open(context, const V2AppLockPage()),
      ),
      const V2GroupLabel('사용 안내'),
      V2ListRow(
        title: 'AI 처리 고지',
        subtitle: '전송 내용과 제공사 확인',
        onTap: () => _open(context, const V2AiNoticePage()),
      ),
      V2ListRow(
        title: '음성 기록',
        subtitle: kIsWeb ? '웹에서 꿈을 말로 남기는 방법' : '기기 내 음성 인식 안내',
        onTap: () => _open(context, const V2VoicePage()),
      ),
      if (extras case final extra?) ...[const V2GroupLabel('미리보기'), extra],
    ],
  );
}

/// A settings page: back control, large serif title, an explanation, then
/// rows. The header gains a surface and a small title once content scrolls.
class V2SettingsFrame extends StatefulWidget {
  const V2SettingsFrame({
    super.key,
    required this.title,
    required this.children,
    this.description,
    this.backLabel = '설정으로 돌아가기',
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final String backLabel;

  @override
  State<V2SettingsFrame> createState() => _V2SettingsFrameState();
}

class _V2SettingsFrameState extends State<V2SettingsFrame> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.hasClients && _scroll.offset > 24;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return V2Page(
      mood: V2Mood.quiet,
      child: Column(
        children: [
          V2ContextHeaderBar(
            elevated: _scrolled,
            backLabel: widget.backLabel,
            title: widget.title,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    V2Space.gutter,
                    V2Space.xs,
                    V2Space.gutter,
                    V2Space.xxl + bottom,
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        v2KeepAll(widget.title),
                        style: V2Type.display,
                      ),
                    ),
                    if (widget.description case final text?) ...[
                      const SizedBox(height: V2Space.xs),
                      Text(
                        v2KeepAll(text),
                        style: V2Type.body.copyWith(color: V2Color.ink2),
                      ),
                    ],
                    const SizedBox(height: V2Space.xs),
                    ...widget.children,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back control plus a small title that appears once the large one scrolls
/// away.
class V2ContextHeaderBar extends StatelessWidget {
  const V2ContextHeaderBar({
    super.key,
    required this.elevated,
    required this.backLabel,
    required this.title,
  });

  final bool elevated;
  final String backLabel;
  final String title;

  @override
  Widget build(BuildContext context) => V2ContextHeader(
    elevated: elevated,
    leading: V2IconButton(
      icon: Icons.arrow_back_rounded,
      semanticLabel: backLabel,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: ExcludeSemantics(
      child: AnimatedOpacity(
        duration: V2Motion.of(context, V2Motion.quick),
        opacity: elevated ? 1 : 0,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: V2Type.headline.copyWith(fontSize: 17),
        ),
      ),
    ),
  );
}

/// A titled block of explanation inside a settings page.
class _Info extends StatelessWidget {
  const _Info(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: V2Space.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v2KeepAll(title), style: V2Type.headline.copyWith(fontSize: 17)),
        const SizedBox(height: 6),
        Text(
          v2KeepAll(body),
          style: V2Type.bodySmall.copyWith(color: V2Color.ink2),
        ),
      ],
    ),
  );
}

class V2ReadingSettingsPage extends ConsumerWidget {
  const V2ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(uiPreferencesProvider);
    return V2SettingsFrame(
      title: '읽기와 종이',
      description: '이 기기에 저장돼요. 원고의 내용은 바뀌지 않아요.',
      children: [
        const SizedBox(height: V2Space.md),
        const V2ReadingSettingsPanel(showTitle: false),
        const SizedBox(height: V2Space.lg),
        Text(
          '한 장면이 나의 문장으로 남았다.',
          style: V2Type.reading.copyWith(
            fontSize: V2Type.reading.fontSize! * preferences.readerScale,
          ),
        ),
        if (preferences.loadFailed) ...[
          const SizedBox(height: V2Space.md),
          const V2Notice(
            message: '저장된 설정을 불러오지 못해 기본값으로 표시했어요. 다시 고르면 저장을 재시도해요.',
          ),
        ],
      ],
    );
  }
}

class V2AppLockPage extends ConsumerWidget {
  const V2AppLockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    return V2SettingsFrame(
      title: '앱 잠금',
      description: '이 기기를 잠시 비울 때도 꿈과 원고를 보호해요.',
      children: [
        const SizedBox(height: V2Space.md),
        V2SwitchRow(
          title: '앱 잠금 사용',
          subtitle: '앱을 다시 열 때 기기 인증 요청',
          value: lock.enabled,
          onChanged: lock.authenticating
              ? null
              : (value) async {
                  final changed = await lock.setEnabled(value);
                  if (!changed && context.mounted) {
                    showV2Toast(context, '기기 인증을 완료해야 설정을 바꿀 수 있어요.');
                  }
                },
        ),
        const _Info(
          '기기 안에서만 확인해요',
          'Face ID 또는 기기 암호로 앱을 열 수 있어요. 인증 정보는 기기 밖으로 전송되지 않아요.',
        ),
      ],
    );
  }
}

class V2AiNoticePage extends ConsumerStatefulWidget {
  const V2AiNoticePage({super.key});

  @override
  ConsumerState<V2AiNoticePage> createState() => _V2AiNoticePageState();
}

class _V2AiNoticePageState extends ConsumerState<V2AiNoticePage> {
  late Future<AiConsentPolicy> _policy = ref
      .read(aiConsentRepositoryProvider)
      .loadPolicy();

  void _retry() => setState(() {
    _policy = ref.read(aiConsentRepositoryProvider).loadPolicy();
  });

  @override
  Widget build(BuildContext context) => V2SettingsFrame(
    title: 'AI 처리 고지',
    description: '꿈 기록이 AI 장면 생성에 쓰이는 방식과 제공사를 확인해요.',
    children: [
      FutureBuilder<AiConsentPolicy>(
        future: _policy,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return V2InlineStatus(
              '현재 고지를 불러오지 못했어요.',
              action: V2Button.secondary(label: '다시 시도', onPressed: _retry),
            );
          }
          if (!snapshot.hasData) {
            return const V2InlineStatus('현재 고지를 불러오는 중이에요.', waiting: true);
          }
          final policy = snapshot.requireData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Info('현재 안내', policy.message),
              const V2GroupLabel('처리 제공사'),
              for (final provider in policy.providers) ...[
                Text(
                  provider.name,
                  style: V2Type.headline.copyWith(fontSize: 17),
                ),
                V2PolicyLink(
                  label: '${provider.name} 이용 약관',
                  uri: provider.termsUrl,
                ),
                if (provider.dataUrl case final url?)
                  V2PolicyLink(label: '${provider.name} 데이터 처리 안내', uri: url),
                const SizedBox(height: V2Space.sm),
              ],
              V2Meta('고지 버전 ${policy.version}'),
            ],
          );
        },
      ),
    ],
  );
}

class V2VoicePage extends StatelessWidget {
  const V2VoicePage({super.key, this.web = kIsWeb});

  /// The web copy: no recording here, keyboard dictation is a separate iOS
  /// feature. Defaults to the platform; tests set it explicitly.
  final bool web;

  @override
  Widget build(BuildContext context) => V2SettingsFrame(
    title: '음성 기록',
    description: '꿈을 말로 남길 때 음성이 어떻게 처리되는지 안내해요.',
    children: web
        ? const [
            _Info(
              '웹에서는 직접 적어요',
              '무무몽 녹음은 iPhone 앱의 기기 내 기능이에요. 이 웹 체험판에서는 사용할 수 없고, 홈 화면에 설치해도 녹음 기능이 생기지는 않아요.',
            ),
            _Info(
              '키보드 받아쓰기',
              '키보드에 음성 입력 버튼이 있으면 사용할 수 있어요. 무무몽 녹음과 다른 iOS 기능이며, 처리는 기기의 받아쓰기 설정을 따라요.',
            ),
            _Info(
              '마이크를 켜지 않아요',
              '무무몽이 브라우저 마이크를 켜거나 음성을 서버로 보내지는 않아요. 작성 중인 내용은 그대로 유지돼요.',
            ),
          ]
        : const [
            _Info(
              '음성은 기기 안에서만',
              '지원하는 iPhone에서는 기기 내 음성 인식을 사용해요. 음성 파일을 저장하거나 서버로 보내지 않아요.',
            ),
            _Info('직접 입력도 가능해요', '기기에서 음성 인식을 사용할 수 없다면 텍스트로 꿈을 기록할 수 있어요.'),
          ],
  );
}

class V2RecordsPage extends ConsumerStatefulWidget {
  const V2RecordsPage({super.key});

  @override
  ConsumerState<V2RecordsPage> createState() => _V2RecordsPageState();
}

class _V2RecordsPageState extends ConsumerState<V2RecordsPage> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _export() async {
    final confirmed = await showV2Dialog<bool>(
      context,
      title: '내 기록 내보내기',
      body:
          '꿈 원문, 작성 중인 초안, 원고와 출처 정보가 JSON 파일에 포함돼요. 공유할 곳은 다음 화면에서 직접 선택해 주세요.',
      actions: (dialog) => [
        V2Button.secondary(
          label: '취소',
          size: V2ButtonSize.compact,
          onPressed: () => Navigator.pop(dialog, false),
        ),
        V2Button(
          label: '내보내기',
          size: V2ButtonSize.compact,
          onPressed: () => Navigator.pop(dialog, true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _exporting = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await ref
          .read(recordActionsProvider)
          .shareExport(
            origin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
    } on Object {
      if (mounted) showV2Toast(context, '내보내지 못했어요. 기록은 그대로 보관되어 있어요.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAll() async {
    final typed = TextEditingController();
    final confirmed = await showV2Dialog<bool>(
      context,
      title: '모든 기록 삭제',
      body: '꿈 원문과 원고를 되돌릴 수 없게 삭제해요. 먼저 내보내기를 권해요.',
      content: V2TextField(
        controller: typed,
        label: '계속하려면 $deleteEverythingConfirmation 입력',
        fieldKey: const Key('v2-delete-confirmation'),
      ),
      actions: (dialog) => [
        V2Button.secondary(
          label: '취소',
          size: V2ButtonSize.compact,
          onPressed: () => Navigator.pop(dialog, false),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: typed,
          builder: (context, value, _) => V2Button(
            label: '영구 삭제',
            size: V2ButtonSize.compact,
            onPressed: confirmsDeleteEverything(value.text)
                ? () => Navigator.pop(dialog, true)
                : null,
          ),
        ),
      ],
    );
    // The dialog route may still be animating out; let it finish first.
    WidgetsBinding.instance.addPostFrameCallback((_) => typed.dispose());
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(recordActionsProvider).deleteEverything();
      if (!mounted) return;
      showV2Toast(context, '모든 기록을 삭제했어요.');
      // Leave the settings pages: the gate below now decides what to show.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Object {
      if (mounted) {
        showV2Toast(context, '삭제 상태를 확인하지 못했어요. 다시 로그인해 남은 기록을 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(v2PreviewProvider);
    return V2SettingsFrame(
      title: '기록 관리',
      description: '내 기록의 사본을 보관하거나, 무무몽에서 지울 수 있어요.',
      children: [
        const _Info(
          '기록은 내 것이에요',
          '꿈 · 원고 · 출처 · 작성 중인 초안을 JSON 파일로 내보낼 수 있어요.',
        ),
        const SizedBox(height: V2Space.md),
        if (preview) ...[
          const V2Notice(message: '미리보기에서는 실제 기록을 내보내거나 지우지 않아요.'),
          const SizedBox(height: V2Space.md),
        ],
        V2ListRow(
          title: _exporting ? '파일 준비 중' : '내 기록 내보내기',
          subtitle: 'JSON 사본 저장 · 꿈 원문과 초안 포함',
          busy: _exporting,
          onTap: preview ? null : _export,
        ),
        V2ListRow(
          title: _deleting ? '삭제 중' : '모든 기록 삭제',
          subtitle: '계정이 있으면 서버 기록과 계정도 함께 삭제',
          destructive: true,
          busy: _deleting,
          onTap: preview ? null : _deleteAll,
        ),
      ],
    );
  }
}

/// Author preferences only. Saving never starts generation or rewrites
/// passages (the same rule as V1 GenerationSettingsScreen).
class V2GenerationSettingsPage extends ConsumerStatefulWidget {
  const V2GenerationSettingsPage({super.key});

  @override
  ConsumerState<V2GenerationSettingsPage> createState() =>
      _V2GenerationSettingsPageState();
}

class _V2GenerationSettingsPageState
    extends ConsumerState<V2GenerationSettingsPage> {
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
      loading: () => const V2InlineStatus('설정을 불러오는 중이에요.', waiting: true),
      error: (_, _) => const V2InlineStatus('원고 설정을 불러오지 못했어요.'),
      data: (value) => value == null
          ? const V2InlineStatus('첫 원고를 시작한 뒤 설정할 수 있어요.')
          : ref
                .watch(generationSettingsProvider(value.id))
                .when(
                  loading: () =>
                      const V2InlineStatus('설정을 불러오는 중이에요.', waiting: true),
                  error: (_, _) => const V2InlineStatus('설정을 불러오지 못했어요.'),
                  data: (state) => state == null
                      ? const V2InlineStatus('설정할 원고가 없어요.')
                      : _editor(value, state),
                ),
    );
    return V2SettingsFrame(
      title: '이후 장면 설정',
      description: '저장 후 시작하는 생성부터 적용돼요. 기존 원고와 내가 쓴 문장은 그대로예요.',
      children: [content],
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
    final message = closed
        ? '완결을 시작한 원고의 설정은 바꿀 수 없어요.'
        : conflict
        ? '다른 기기에서 설정이 바뀌었어요. 어느 설정을 사용할지 선택해 주세요.'
        : pending
        ? '동기화 대기 중이에요. 서버 확인 전에는 새 생성을 시작하지 않아요. 기록과 원고 읽기는 계속할 수 있어요.'
        : '이미 진행 중인 생성은 시작할 때의 설정을 유지해요.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: V2Space.xs),
        V2Meta('확인된 설정 v${state.version}'),
        Opacity(
          opacity: locked ? .55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const V2GroupLabel('각색'),
              _options(
                AdaptationLevel.values,
                selected.adaptation,
                locked,
                (item) => _draft = GenerationSettings(
                  adaptation: item,
                  style: selected.style,
                  narrativeVoice: selected.narrativeVoice,
                ),
              ),
              const V2GroupLabel('문체'),
              _options(
                WritingStyle.values,
                selected.style,
                locked,
                (item) => _draft = GenerationSettings(
                  adaptation: selected.adaptation,
                  style: item,
                  narrativeVoice: selected.narrativeVoice,
                ),
              ),
              const V2GroupLabel('시점'),
              _options(
                NarrativeVoice.values,
                selected.narrativeVoice,
                locked,
                (item) => _draft = GenerationSettings(
                  adaptation: selected.adaptation,
                  style: selected.style,
                  narrativeVoice: item,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: V2Space.lg),
        Text(v2KeepAll(message), style: V2Type.bodySmall),
        if (conflict) ...[
          const SizedBox(height: V2Space.sm),
          Text(
            '이 기기의 선택: ${_summary(state.selected)}',
            style: V2Type.bodySmall,
          ),
          const SizedBox(height: V2Space.xxs),
          Text('서버의 설정: ${_summary(state.confirmed)}', style: V2Type.bodySmall),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: V2Space.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: V2Type.bodySmall.copyWith(color: V2Color.alert),
            ),
          ),
        ],
        const SizedBox(height: V2Space.lg),
        if (!closed)
          V2Button(
            label: conflict
                ? '이 기기의 선택 적용'
                : pending
                ? '동기화 다시 시도'
                : '설정 저장',
            expand: true,
            loading: _saving,
            loadingLabel: '저장 중',
            onPressed:
                _saving ||
                    (!pending && !conflict && selected == state.confirmed)
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
        if (conflict)
          Center(
            child: V2TextAction(
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
          ),
      ],
    );
  }

  Widget _options<T extends Enum>(
    List<T> values,
    T selected,
    bool locked,
    void Function(T item) choose,
  ) => Wrap(
    spacing: V2Space.xs,
    runSpacing: V2Space.xs,
    children: [
      for (final item in values)
        V2ChoiceChip(
          label: _label(item),
          selected: item == selected,
          onSelected: locked ? null : () => setState(() => choose(item)),
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

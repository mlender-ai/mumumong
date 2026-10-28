// V2 Onboarding / Brand Introduction (brief §7.1). The constructor contract
// matches V1 OnboardingScreen so AuthGate can host it unchanged after GO.
// Page 1: a halftone manuscript prints itself over a blurred sky and moves
// away from the finger. Page 2: AI processing notice and consent.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/auth/ai_consent.dart';
import '../components/brand.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../components/policy_link.dart';
import '../components/progress.dart';
import '../design/atmosphere.dart';
import '../design/dot_matrix.dart';
import '../design/halftone.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'format.dart';

class V2OnboardingScreen extends ConsumerStatefulWidget {
  const V2OnboardingScreen({
    super.key,
    this.policy,
    this.initialPage = 0,
    this.busy = false,
    this.onApplePressed,
    this.onTrialPressed,
    this.onConsentPressed,
    this.entryActionLabel,
    this.consentActionLabel,
    this.entryCaption,
    this.consentNote,
    this.consentError,
  });

  final AiConsentPolicy? policy;
  final int initialPage;
  final bool busy;
  final ValueChanged<int>? onApplePressed;
  final ValueChanged<int>? onTrialPressed;
  final ValueChanged<int>? onConsentPressed;
  final String? entryActionLabel;
  final String? consentActionLabel;
  final String? entryCaption;

  /// Extra line under the consent action (the preview says it sends nothing).
  final String? consentNote;

  /// Shown above the action when the last acceptance was not recorded.
  final String? consentError;

  @override
  ConsumerState<V2OnboardingScreen> createState() => _V2OnboardingScreenState();
}

class _V2OnboardingScreenState extends ConsumerState<V2OnboardingScreen> {
  late final PageController _pages;
  late int _page;
  late Future<AiConsentPolicy> _policyFuture;
  bool _ageConfirmed = false;
  bool _aiConsented = false;
  bool _details = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, 1);
    _pages = PageController(initialPage: _page);
    _policyFuture = widget.policy == null
        ? ref.read(aiConsentRepositoryProvider).loadPolicy()
        : Future.value(widget.policy);
  }

  @override
  void didUpdateWidget(covariant V2OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.policy != oldWidget.policy) {
      _policyFuture = widget.policy == null
          ? ref.read(aiConsentRepositoryProvider).loadPolicy()
          : Future.value(widget.policy);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (V2Motion.reduced(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: V2Motion.page,
        curve: V2Motion.settle,
      );
    }
  }

  void _retryPolicy() => setState(() {
    _policyFuture = ref.read(aiConsentRepositoryProvider).loadPolicy();
  });

  bool get _webTrial => kIsWeb && widget.onTrialPressed != null;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: V2Color.paper,
        body: V2Atmosphere(
          mood: _page == 0 ? V2Mood.intro : V2Mood.home,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        V2Space.gutter,
                        V2Space.sm,
                        V2Space.gutter,
                        0,
                      ),
                      child: Row(
                        children: [
                          const V2Wordmark(animate: true),
                          const Spacer(),
                          V2DotMatrix(
                            '0${_page + 1}/02',
                            pitch: 2,
                            color: V2Color.ink2,
                            semanticsLabel: '2단계 중 ${_page + 1}단계',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<AiConsentPolicy>(
                        future: _policyFuture,
                        builder: (context, snapshot) => PageView(
                          controller: _pages,
                          onPageChanged: (page) => setState(() => _page = page),
                          children: [
                            _EntryPage(
                              onContinue: () => _go(1),
                              actionLabel:
                                  widget.entryActionLabel ??
                                  (_webTrial ? '체험 계정으로 시작' : 'Apple로 시작하기'),
                              appleIcon:
                                  widget.entryActionLabel == null && !_webTrial,
                              caption:
                                  widget.entryCaption ??
                                  '시작 전에 AI 처리 고지와 동의를 확인합니다.',
                            ),
                            snapshot.data == null
                                ? _PolicyLoading(
                                    failed: snapshot.hasError,
                                    onRetry: _retryPolicy,
                                  )
                                : _consentPage(snapshot.data!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _consentPage(AiConsentPolicy policy) {
    final providers = policy.providers.map((p) => p.name).join(', ');
    final enabled = _ageConfirmed && _aiConsented && !widget.busy;
    final label = widget.busy
        ? '준비하고 있어요'
        : widget.onConsentPressed != null
        ? widget.consentActionLabel ?? '동의하고 계속'
        : _webTrial
        ? '동의하고 시작'
        : 'Apple로 계속하기';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        V2Space.gutter,
        V2Space.xl,
        V2Space.gutter,
        V2Space.lg,
      ),
      child: V2Surface(
        kind: V2SurfaceKind.elevated,
        radius: V2Radius.hero,
        chroma: .25,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                v2KeepAll('시작 전,\n두 가지만 확인해 주세요.'),
                style: V2Type.display,
              ),
            ),
            const SizedBox(height: V2Space.md),
            Text(
              v2KeepAll(
                providers.isEmpty
                    ? policy.message
                    : '꿈을 소설로 만들기 위해 $providers로 내용을 보내요.',
              ),
              style: V2Type.body,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: V2TextAction(
                key: const Key('v2-consent-details-toggle'),
                label: _details ? 'AI 처리 안내 접기' : 'AI 처리 안내 보기',
                icon: _details
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                onPressed: () => setState(() => _details = !_details),
              ),
            ),
            if (_details) ...[
              Text(v2KeepAll(policy.message), style: V2Type.bodySmall),
              const SizedBox(height: V2Space.sm),
              for (final provider in policy.providers) ...[
                V2PolicyLink(
                  label: '${provider.name} 이용 약관',
                  uri: provider.termsUrl,
                ),
                if (provider.dataUrl case final dataUrl?)
                  V2PolicyLink(
                    label: '${provider.name} 데이터 처리 안내',
                    uri: dataUrl,
                  ),
              ],
              V2Meta('고지 버전 ${policy.version}'),
              const SizedBox(height: V2Space.sm),
            ],
            const SizedBox(height: V2Space.xs),
            V2CheckRow(
              key: const Key('v2-age-confirmation'),
              label: '만 14세 이상입니다.',
              value: _ageConfirmed,
              onChanged: (value) => setState(() => _ageConfirmed = value),
            ),
            V2CheckRow(
              key: const Key('v2-ai-consent'),
              label: '꿈 내용의 AI 처리에 동의합니다.',
              value: _aiConsented,
              onChanged: (value) => setState(() => _aiConsented = value),
            ),
            const SizedBox(height: V2Space.lg),
            if (widget.consentError case final error?) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const Key('v2-consent-error'),
                  textAlign: TextAlign.center,
                  style: V2Type.bodySmall.copyWith(color: V2Color.alert),
                ),
              ),
              const SizedBox(height: V2Space.sm),
            ],
            V2Button(
              label: label,
              icon: widget.onConsentPressed == null && !_webTrial
                  ? Icons.apple
                  : null,
              expand: true,
              loading: widget.busy,
              loadingLabel: '준비하고 있어요',
              onPressed: !enabled
                  ? null
                  : () {
                      final action =
                          widget.onConsentPressed ??
                          (_webTrial
                              ? widget.onTrialPressed
                              : widget.onApplePressed);
                      action?.call(policy.version);
                    },
            ),
            if (widget.onConsentPressed == null &&
                !_webTrial &&
                widget.onTrialPressed != null)
              Center(
                child: V2TextAction(
                  label: '체험 계정으로 시작',
                  onPressed: enabled
                      ? () => widget.onTrialPressed!(policy.version)
                      : null,
                ),
              ),
            if (_webTrial) ...[
              const SizedBox(height: V2Space.sm),
              const V2Meta(
                '이 브라우저에서 이어 쓸 수 있어요. 브라우저 데이터를 지우면 기록을 복구할 수 없어요.',
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.consentNote != null) ...[
              const SizedBox(height: V2Space.sm),
              V2Meta(
                widget.consentNote!,
                textAlign: TextAlign.center,
                color: V2Color.sky700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryPage extends StatelessWidget {
  const _EntryPage({
    required this.onContinue,
    required this.actionLabel,
    required this.appleIcon,
    required this.caption,
  });

  final VoidCallback onContinue;
  final String actionLabel;
  final bool appleIcon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final largeType = MediaQuery.textScalerOf(context).scale(16) > 21;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          V2Space.gutter,
          0,
          V2Space.gutter,
          V2Space.md,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - V2Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!largeType)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    36,
                    V2Space.lg,
                    36,
                    V2Space.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .40,
                    ),
                    child: const Center(child: _BrandObject()),
                  ),
                )
              else
                const SizedBox(height: V2Space.lg),
              V2Surface(
                kind: V2SurfaceKind.elevated,
                radius: V2Radius.hero,
                chroma: .35,
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        '꿈이 자라,\n이야기가 되는 곳.',
                        style: V2Type.displayXL,
                      ),
                    ),
                    const SizedBox(height: V2Space.sm),
                    Text(
                      v2KeepAll('막 깨어난 장면을 남겨 보세요. 기억의 조각이 모여 한 권의 원고가 됩니다.'),
                      style: V2Type.body,
                    ),
                    const SizedBox(height: V2Space.lg),
                    V2Button(
                      label: actionLabel,
                      icon: appleIcon ? Icons.apple : null,
                      expand: true,
                      haptic: null,
                      onPressed: onContinue,
                    ),
                    const SizedBox(height: V2Space.xxs),
                    Center(
                      child: V2TextAction(
                        label: '가상 꿈 미리 보기',
                        onPressed: () => showV2Sheet<void>(
                          context,
                          builder: (_) => const _SampleStory(),
                        ),
                      ),
                    ),
                    V2Meta(caption, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand object: a manuscript page that prints itself once, then moves
/// away from the finger and settles back (Reference C).
class _BrandObject extends StatelessWidget {
  const _BrandObject();

  @override
  Widget build(BuildContext context) => V2Surface(
    kind: V2SurfaceKind.frosted,
    radius: V2Radius.card,
    chroma: .2,
    padding: const EdgeInsets.all(18),
    child: const V2Manuscript(
      motif: V2Motif.door,
      seed: 2026,
      progress: .74,
      assemble: true,
      interactive: true,
      columns: 30,
      semanticsLabel: '도트로 인쇄된 원고 한 장. 손가락으로 만지면 도트가 흩어졌다 돌아와요.',
    ),
  );
}

class _SampleStory extends StatelessWidget {
  const _SampleStory();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .78,
    ),
    child: const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          V2Meta(
            '설명을 위해 새로 지은 가상 예시 · 실제 AI 생성 결과가 아니에요.',
            color: V2Color.sky700,
          ),
          SizedBox(height: V2Space.md),
          Text('한 조각에서 시작해요', style: V2Type.title),
          SizedBox(height: V2Space.lg),
          V2Meta('기록한 꿈'),
          SizedBox(height: V2Space.xs),
          Text(
            '빈 역에서 종이배가 들어 있는 우편함을 열었다. 배를 펼치자 내일 날짜가 적혀 있었다.',
            style: V2Type.capture,
          ),
          SizedBox(height: V2Space.lg),
          V2Meta('●  꿈에서 온 문장'),
          SizedBox(height: V2Space.xs),
          Text(
            '역에는 아무도 없었다. 나는 우편함에서 종이배를 꺼냈다. 접힌 선을 펼치자 내일 날짜가 드러났다.',
            style: V2Type.reading,
          ),
          SizedBox(height: V2Space.md),
          V2Meta('○  장면을 잇는 문장'),
          SizedBox(height: V2Space.xs),
          Text('나는 종이를 다시 접지 못하고 한참 서 있었다.', style: V2Type.reading),
          SizedBox(height: V2Space.lg),
          Text(
            '실제 원고에서는 문단의 출처를 열어 어떤 꿈에서 왔는지 확인하고, 내 문장으로 고칠 수 있어요.',
            style: V2Type.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _PolicyLoading extends StatelessWidget {
  const _PolicyLoading({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(V2Space.gutter),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failed ? 'AI 처리 안내를\n불러오지 못했어요' : '안내를 불러오는 중',
              textAlign: TextAlign.center,
              style: V2Type.title,
            ),
            if (failed) ...[
              const SizedBox(height: V2Space.xs),
              const Text('안내를 확인하기 전에는 로그인하지 않아요.', style: V2Type.bodySmall),
              const SizedBox(height: V2Space.lg),
              V2Button(label: '다시 시도', onPressed: onRetry),
            ],
          ],
        ),
      ),
    ),
  );
}

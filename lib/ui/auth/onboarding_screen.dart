import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dream_atmosphere.dart';
import '../../core/design/thinking_orb.dart';
import 'ai_consent.dart';
import '../shared/policy_link.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
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
    this.onMotionPreview,
    this.headerAction,
  });

  /// A supplied policy is the one just loaded by the authenticated gate.
  final AiConsentPolicy? policy;
  final int initialPage;
  final bool busy;
  final ValueChanged<int>? onApplePressed;
  final ValueChanged<int>? onTrialPressed;
  final ValueChanged<int>? onConsentPressed;
  final String? entryActionLabel;
  final String? consentActionLabel;
  final String? entryCaption;
  final VoidCallback? onMotionPreview;
  final Widget? headerAction;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pages;
  late int _page;
  late Future<AiConsentPolicy> _policyFuture;
  bool _ageConfirmed = false;
  bool _aiConsented = false;

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
  void didUpdateWidget(covariant OnboardingScreen oldWidget) {
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

  void _showConsent() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(1);
      return;
    }
    _pages.animateToPage(
      1,
      duration: MongMotion.page,
      curve: MongMotion.pageCurve,
    );
  }

  void _retryPolicy() {
    setState(() {
      _policyFuture = ref.read(aiConsentRepositoryProvider).loadPolicy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final webTrial = kIsWeb && widget.onTrialPressed != null;
    final night = Theme.of(context).brightness == Brightness.dark;
    final ink = night ? MongColor.nightInk : MongColor.ink;
    final muted = night ? MongColor.nightMeta : MongColor.ink3;
    return FutureBuilder<AiConsentPolicy>(
      future: _policyFuture,
      builder: (context, snapshot) {
        final policy = snapshot.data;
        return Scaffold(
          backgroundColor: night ? const Color(0xFF050C18) : MongColor.paper,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: (MediaQuery.sizeOf(context).height * .72).clamp(
                  330.0,
                  680.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: DreamAtmosphere(
                      night: night,
                      animate: _page == 0,
                      strength: _page == 0 ? 1 : .18,
                      // Large type moves the headline into the upper field.
                      // Decoration must never sit underneath readable copy.
                      memoryObject:
                          _page == 0 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 20,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: MongSpace.xs,
                            children: [
                              Text(
                                'MUMUMONG',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: ink,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MetaText('0${_page + 1} / 02', color: muted),
                                  ?widget.headerAction,
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: PageView(
                              controller: _pages,
                              onPageChanged: (page) =>
                                  setState(() => _page = page),
                              children: [
                                DreamEntryContent(
                                  onContinue: _showConsent,
                                  webTrial: webTrial,
                                  actionLabel: widget.entryActionLabel,
                                  caption: widget.entryCaption,
                                  onMotionPreview: widget.onMotionPreview,
                                ),
                                policy == null
                                    ? _ConsentLoadingPage(
                                        hasError: snapshot.hasError,
                                        onRetry: _retryPolicy,
                                      )
                                    : _ConsentPage(
                                        policy: policy,
                                        ageConfirmed: _ageConfirmed,
                                        aiConsented: _aiConsented,
                                        onAgeChanged: (value) => setState(
                                          () => _ageConfirmed = value,
                                        ),
                                        onConsentChanged: (value) => setState(
                                          () => _aiConsented = value,
                                        ),
                                        action: _consentAction(
                                          policy,
                                          webTrial,
                                        ),
                                        browserBound: webTrial,
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _canProceed => _ageConfirmed && _aiConsented;

  Widget _consentAction(AiConsentPolicy policy, bool webTrial) {
    final enabled = _canProceed && !widget.busy;
    return MongActionGroup(
      primary: GlassActionButton(
        label: widget.busy
            ? '준비하고 있어요'
            : widget.onConsentPressed != null
            ? widget.consentActionLabel ?? '동의하고 계속'
            : webTrial
            ? '동의하고 시작'
            : 'Apple로 계속하기',
        icon: widget.onConsentPressed == null && !webTrial ? Icons.apple : null,
        onPressed: !enabled
            ? null
            : () {
                final action =
                    widget.onConsentPressed ??
                    (webTrial ? widget.onTrialPressed : widget.onApplePressed);
                action?.call(policy.version);
              },
      ),
      secondary: [
        if (widget.onConsentPressed == null &&
            !webTrial &&
            widget.onTrialPressed != null)
          TextButton(
            onPressed: enabled
                ? () => widget.onTrialPressed!(policy.version)
                : null,
            child: const Text('체험 계정으로 시작'),
          ),
      ],
    );
  }
}

class DreamEntryContent extends StatelessWidget {
  const DreamEntryContent({
    super.key,
    required this.onContinue,
    required this.webTrial,
    this.actionLabel,
    this.caption,
    this.onMotionPreview,
  });

  final VoidCallback onContinue;
  final bool webTrial;
  final String? actionLabel;
  final String? caption;
  final VoidCallback? onMotionPreview;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '꿈이 자라,\n이야기가 되는 곳.',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: night ? MongColor.nightInk : MongColor.ink,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '막 깨어난 장면을 남겨 보세요.\n당신의 꿈에서 이야기가 시작됩니다.',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: night ? MongColor.nightMeta : MongColor.ink2,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: MongSpace.xl),
              MongActionGroup(
                primary: GlassActionButton(
                  label:
                      actionLabel ?? (webTrial ? '체험 계정으로 시작' : 'Apple로 시작하기'),
                  icon: actionLabel != null || webTrial ? null : Icons.apple,
                  lightContent: night,
                  onPressed: onContinue,
                ),
                secondary: [
                  TextButton(
                    onPressed:
                        onMotionPreview ??
                        () => Navigator.of(
                          context,
                        ).push(quietPageRoute(const _SampleStoryScreen())),
                    child: Text(
                      onMotionPreview == null ? '가상 꿈 미리 보기' : 'Orb 모션 보기',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MetaText(
                caption ?? '시작 전에 AI 처리 고지와 동의를 확인합니다.',
                color: night ? MongColor.nightMeta : MongColor.ink3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentPage extends StatefulWidget {
  const _ConsentPage({
    required this.policy,
    required this.ageConfirmed,
    required this.aiConsented,
    required this.onAgeChanged,
    required this.onConsentChanged,
    required this.action,
    required this.browserBound,
  });

  final AiConsentPolicy policy;
  final bool ageConfirmed;
  final bool aiConsented;
  final ValueChanged<bool> onAgeChanged;
  final ValueChanged<bool> onConsentChanged;
  final Widget action;
  final bool browserBound;

  @override
  State<_ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<_ConsentPage> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    final providers = policy.providers.map((p) => p.name).join(', ');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MongSpace.lg),
      children: [
        Text(
          '시작 전,\n두 가지만 확인해 주세요.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: MongSpace.md),
        Text(
          providers.isEmpty
              ? policy.message
              : '꿈을 소설로 만들기 위해 $providers AI로 내용을 보내요.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: MongSpace.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('consent-details-toggle'),
            onPressed: () => setState(() => _details = !_details),
            icon: Icon(
              _details ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            label: Text(_details ? 'AI 처리 안내 접기' : 'AI 처리 안내 보기'),
          ),
        ),
        if (_details) ...[
          const SizedBox(height: MongSpace.sm),
          Text(
            policy.message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
          const SizedBox(height: MongSpace.md),
          for (final provider in policy.providers) ...[
            PolicyLink(label: '${provider.name} 이용 약관', uri: provider.termsUrl),
            if (provider.dataUrl case final dataUrl?)
              PolicyLink(label: '${provider.name} 데이터 처리 안내', uri: dataUrl),
          ],
          MetaText('고지 버전 ${policy.version}'),
        ],
        const SizedBox(height: MongSpace.lg),
        CheckboxListTile(
          key: const Key('age-confirmation'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            '만 14세 이상입니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          value: widget.ageConfirmed,
          onChanged: (value) => widget.onAgeChanged(value == true),
        ),
        CheckboxListTile(
          key: const Key('ai-consent'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            '꿈 내용의 AI 처리에 동의합니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          value: widget.aiConsented,
          onChanged: (value) => widget.onConsentChanged(value == true),
        ),
        const SizedBox(height: MongSpace.xl),
        widget.action,
        if (widget.browserBound) ...[
          const SizedBox(height: MongSpace.md),
          const MetaText(
            '이 브라우저에서 이어 쓸 수 있어요.\n브라우저 데이터를 지우면 기록을 복구할 수 없어요.',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _SampleStoryScreen extends StatelessWidget {
  const _SampleStoryScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('가상 꿈 미리 보기')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const MetaText('설명을 위해 새로 지은 가상 예시 · 실제 AI 생성 결과가 아니에요.'),
            const SizedBox(height: 32),
            Text(
              '한 조각에서 시작해요',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            const MetaText('기록한 꿈'),
            const SizedBox(height: 8),
            const Text('빈 역에서 종이배가 들어 있는 우편함을 열었다. 배를 펼치자 내일 날짜가 적혀 있었다.'),
            const SizedBox(height: 32),
            const MetaText('꿈에서 온 문장 · D'),
            const SizedBox(height: 8),
            Text(
              '역에는 아무도 없었다. 나는 우편함에서 종이배를 꺼냈다. 접힌 선을 펼치자 내일 날짜가 드러났다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const MetaText('장면을 잇는 문장 · C'),
            const SizedBox(height: 8),
            Text(
              '나는 종이를 다시 접지 못하고 한참 서 있었다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text('실제 원고에서는 문단의 출처를 열어 어떤 꿈에서 왔는지 확인하고, 내 문장으로 고칠 수 있어요.'),
          ],
        ),
      ),
    ),
  );
}

class _ConsentLoadingPage extends StatelessWidget {
  const _ConsentLoadingPage({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!hasError) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: 'AI 처리 안내를 불러오는 중',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThinkingOrb(state: DreamOrbState.connecting),
              const SizedBox(height: MongSpace.lg),
              Text(
                '안내를 불러오는 중',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: GlassSurface(
        radius: 28,
        opacity: .32,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MetaText('연결을 확인해 주세요'),
            const SizedBox(height: 14),
            Text(
              'AI 처리 안내를\n불러오지 못했어요.',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '안내를 확인하기 전에는 로그인하지 않아요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),
            GlassActionButton(label: '다시 시도', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

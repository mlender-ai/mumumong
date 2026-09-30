import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/design/design_system.dart';
import 'ai_consent.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.policy,
    this.initialPage = 0,
    this.busy = false,
    this.onApplePressed,
    this.onTrialPressed,
    this.onConsentPressed,
  });

  /// A supplied policy is the one just loaded by the authenticated gate.
  final AiConsentPolicy? policy;
  final int initialPage;
  final bool busy;
  final ValueChanged<int>? onApplePressed;
  final ValueChanged<int>? onTrialPressed;
  final ValueChanged<int>? onConsentPressed;

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
    _page = widget.initialPage.clamp(0, 2);
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

  void _next() {
    if (_page >= 2) return;
    _pages.animateToPage(
      _page + 1,
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
    return FutureBuilder<AiConsentPolicy>(
      future: _policyFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _StatusPage(
            title: snapshot.hasError ? 'AI 처리 고지를 불러오지 못했어요.' : '고지를 불러오는 중',
            action: snapshot.hasError
                ? EditorialButton(label: '다시 시도', onPressed: _retryPolicy)
                : null,
          );
        }
        final policy = snapshot.requireData;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetaText('MUMUMONG · 0${_page + 1} / 03'),
                  const SizedBox(height: 26),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        _StoryPage(
                          title: '꿈을 쓰면,\n원고가 자랍니다.',
                          body:
                              '나의 꿈을 기록하고 하나의 소설로 이어가세요.\n기억나는 꿈이라면 언제 꾼 꿈이어도 괜찮아요.',
                        ),
                        _StoryPage(
                          title: '한 문장에도\n돌아갈 꿈이 있어요.',
                          body:
                              '소설 속 문단은 꿈에서 온 장면(D), 연결·각색한 장면(C), 내가 직접 쓴 문장(U)으로 구분됩니다. 출처를 눌러 어떤 꿈에서 왔는지 확인할 수 있어요.',
                        ),
                        _ConsentPage(
                          policy: policy,
                          ageConfirmed: _ageConfirmed,
                          aiConsented: _aiConsented,
                          onAgeChanged: (value) =>
                              setState(() => _ageConfirmed = value),
                          onConsentChanged: (value) =>
                              setState(() => _aiConsented = value),
                        ),
                      ],
                    ),
                  ),
                  if (_page < 2)
                    EditorialButton(label: '계속', onPressed: _next)
                  else ...[
                    if (widget.onConsentPressed != null)
                      EditorialButton(
                        label: widget.busy ? '동의 기록 중' : '동의하고 계속',
                        onPressed: _canProceed && !widget.busy
                            ? () => widget.onConsentPressed!(policy.version)
                            : null,
                      )
                    else ...[
                      SignInWithAppleButton(
                        text: widget.busy ? 'Apple ID 확인 중' : 'Apple로 계속하기',
                        height: 52,
                        borderRadius: BorderRadius.zero,
                        onPressed: _canProceed && !widget.busy
                            ? () => widget.onApplePressed?.call(policy.version)
                            : null,
                      ),
                      if (widget.onTrialPressed != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _canProceed && !widget.busy
                              ? () => widget.onTrialPressed!(policy.version)
                              : null,
                          child: const Text('체험 계정으로 시작'),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    const MetaText(
                      '동의하지 않으면 계정을 만들거나 원고를 생성할 수 없습니다.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _canProceed => _ageConfirmed && _aiConsented;
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 22),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
          ),
        ],
      ),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.policy,
    required this.ageConfirmed,
    required this.aiConsented,
    required this.onAgeChanged,
    required this.onConsentChanged,
  });

  final AiConsentPolicy policy;
  final bool ageConfirmed;
  final bool aiConsented;
  final ValueChanged<bool> onAgeChanged;
  final ValueChanged<bool> onConsentChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 32),
        Text('내 꿈을 다루는 방식', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 20),
        Text(policy.message),
        const SizedBox(height: 20),
        const MetaText('현재 AI 제공사'),
        const SizedBox(height: 8),
        for (final provider in policy.providers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name),
                InkWell(
                  onTap: () => Clipboard.setData(
                    ClipboardData(text: provider.termsUrl.toString()),
                  ),
                  child: Text(
                    '이용 약관: ${provider.termsUrl} · 탭하여 복사',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (provider.dataUrl case final dataUrl?)
                  InkWell(
                    onTap: () => Clipboard.setData(
                      ClipboardData(text: dataUrl.toString()),
                    ),
                    child: Text(
                      '데이터 처리 안내: $dataUrl · 탭하여 복사',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        CheckboxListTile(
          key: const Key('age-confirmation'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('만 14세 이상입니다.'),
          value: ageConfirmed,
          onChanged: (value) => onAgeChanged(value == true),
        ),
        CheckboxListTile(
          key: const Key('ai-consent'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('꿈 내용의 AI 처리에 동의합니다.'),
          value: aiConsented,
          onChanged: (value) => onConsentChanged(value == true),
        ),
        MetaText('고지 버전 ${policy.version}'),
      ],
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MetaText('MUMUMONG'),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

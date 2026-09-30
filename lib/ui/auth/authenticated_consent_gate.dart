import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import 'ai_consent.dart';
import 'onboarding_screen.dart';

/// Blocks every authenticated page until the current server policy is recorded
/// against the signed-in account. A failed read or write never grants access.
class AuthenticatedConsentGate extends ConsumerStatefulWidget {
  const AuthenticatedConsentGate({
    super.key,
    required this.child,
    this.pendingOnboardingVersion,
  });

  final Widget child;
  final int? pendingOnboardingVersion;

  @override
  ConsumerState<AuthenticatedConsentGate> createState() =>
      _AuthenticatedConsentGateState();
}

class _ConsentCheck {
  const _ConsentCheck(this.policy, this.accepted);

  final AiConsentPolicy policy;
  final bool accepted;
}

class _AuthenticatedConsentGateState
    extends ConsumerState<AuthenticatedConsentGate>
    with WidgetsBindingObserver {
  late Future<_ConsentCheck> _checking;
  bool _accepting = false;
  bool _acceptFailed = false;
  bool _pendingAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checking = _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retry();
  }

  Future<_ConsentCheck> _check() async {
    final repository = ref.read(aiConsentRepositoryProvider);
    final policy = await repository.loadPolicy();
    final record = await repository.loadCurrentUserRecord();
    if (record.isCurrentFor(policy)) return _ConsentCheck(policy, true);

    // The checkboxes were marked before the first sign-in. A changed server
    // version requires the user to see and accept the new notice instead.
    if (!_pendingAttempted &&
        widget.pendingOnboardingVersion == policy.version) {
      _pendingAttempted = true;
      final accepted = await repository.accept(
        version: policy.version,
        ageConfirmed: true,
      );
      if (accepted) {
        final confirmed = await repository.loadCurrentUserRecord();
        if (confirmed.isCurrentFor(policy)) return _ConsentCheck(policy, true);
      }
    }
    return _ConsentCheck(policy, false);
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _acceptFailed = false;
      _checking = _check();
    });
  }

  Future<void> _accept(int version) async {
    if (_accepting) return;
    setState(() {
      _accepting = true;
      _acceptFailed = false;
    });
    try {
      final repository = ref.read(aiConsentRepositoryProvider);
      final accepted = await repository.accept(
        version: version,
        ageConfirmed: true,
      );
      if (!accepted) throw StateError('ai_consent_not_recorded');
      final policy = await repository.loadPolicy();
      final record = await repository.loadCurrentUserRecord();
      if (!record.isCurrentFor(policy)) {
        throw StateError('ai_consent_not_current');
      }
      if (mounted) {
        setState(() => _checking = Future.value(_ConsentCheck(policy, true)));
      }
    } on Object {
      if (mounted) setState(() => _acceptFailed = true);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ConsentCheck>(
      future: _checking,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _GateMessage(title: '동의 기록을 확인하는 중');
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _GateMessage(
            title: 'AI 처리 고지를 확인하지 못했어요.',
            detail: '연결을 확인하고 다시 시도해 주세요. 동의 상태를 확인하기 전에는 원고를 열 수 없어요.',
            action: EditorialButton(label: '다시 시도', onPressed: _retry),
          );
        }
        final check = snapshot.requireData;
        if (check.accepted) return widget.child;
        return Stack(
          children: [
            OnboardingScreen(
              key: ValueKey(check.policy.version),
              policy: check.policy,
              initialPage: 2,
              busy: _accepting,
              onConsentPressed: _accept,
            ),
            if (_acceptFailed)
              const Positioned(
                left: 20,
                right: 20,
                bottom: 4,
                child: Material(
                  color: MongColor.paper,
                  child: Text(
                    '동의를 기록하지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.title, this.detail, this.action});

  final String title;
  final String? detail;
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
              const MetaText('AI NOTICE'),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              if (detail != null) ...[
                const SizedBox(height: 16),
                Text(detail!),
              ],
              const Spacer(),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

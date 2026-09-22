import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/design_system.dart';
import '../../di/providers.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(appLockProvider).load());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(appLockProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.lock();
    } else if (state == AppLifecycleState.resumed && !controller.unlocked) {
      unawaited(controller.unlock());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    if (!lock.loaded || lock.unlocked) return widget.child;
    return Scaffold(
      backgroundColor: MongColor.paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('무무몽', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                const Text('꿈과 원고가 잠겨 있어요.'),
                const SizedBox(height: 28),
                EditorialButton(
                  label: lock.authenticating ? '확인 중' : '잠금 해제',
                  onPressed: lock.authenticating ? null : lock.unlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

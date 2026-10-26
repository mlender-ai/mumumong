import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/design_system.dart';
import '../../di/providers.dart';

class ContentState extends StatelessWidget {
  const ContentState({
    super.key,
    required this.message,
    this.action,
    this.onAction,
  });
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
          ),
          if (action != null) ...[
            const SizedBox(height: MongSpace.xl),
            MongActionGroup(
              primary: EditorialButton(label: action!, onPressed: onAction),
            ),
          ],
        ],
      ),
    ),
  );
}

class OfflineNotice extends ConsumerWidget {
  const OfflineNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(networkConnectedProvider).value == false
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            '네트워크 연결이 없어요. 기기에 저장된 기록은 계속 읽을 수 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.metaInk),
          ),
        )
      : const SizedBox.shrink();
}

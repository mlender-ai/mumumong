import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final policyLinkOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Actual provider URL, with explicit copy fallback and result feedback.
class PolicyLink extends ConsumerWidget {
  const PolicyLink({super.key, required this.label, required this.uri});
  final String label;
  final Uri uri;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> copy() async {
      try {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('주소를 복사했어요. 브라우저에 붙여 넣어 확인할 수 있어요.')),
          );
        }
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('복사하지 못했어요. 다시 시도해 주세요.')),
          );
        }
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () async {
            try {
              if ((uri.scheme == 'https' || uri.scheme == 'http') &&
                  await ref.read(policyLinkOpenerProvider)(uri)) {
                return;
              }
            } on Object {
              /* Offer a visible non-network fallback. */
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('링크를 열지 못했어요.'),
                  action: SnackBarAction(label: '주소 복사', onPressed: copy),
                ),
              );
            }
          },
          child: Text('$label 열기'),
        ),
        IconButton(
          tooltip: '$label 주소 복사',
          onPressed: copy,
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }
}

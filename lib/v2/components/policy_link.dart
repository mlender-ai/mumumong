import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/shared/policy_link.dart' show policyLinkOpenerProvider;
import 'buttons.dart';
import 'feedback.dart';

/// A provider's real policy URL, with a visible copy fallback.
class V2PolicyLink extends ConsumerWidget {
  const V2PolicyLink({super.key, required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> copy() async {
      try {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (context.mounted) {
          showV2Toast(context, '주소를 복사했어요. 브라우저에 붙여 넣어 확인할 수 있어요.');
        }
      } on Object {
        if (context.mounted) showV2Toast(context, '복사하지 못했어요. 다시 시도해 주세요.');
      }
    }

    return Row(
      children: [
        Flexible(
          child: V2TextAction(
            label: '$label 열기',
            icon: Icons.open_in_new_rounded,
            onPressed: () async {
              try {
                if ((uri.scheme == 'https' || uri.scheme == 'http') &&
                    await ref.read(policyLinkOpenerProvider)(uri)) {
                  return;
                }
              } on Object {
                // Visible fallback below.
              }
              if (context.mounted) {
                showV2Toast(context, '링크를 열지 못했어요. 주소 복사를 눌러 주세요.');
              }
            },
          ),
        ),
        V2IconButton(
          icon: Icons.copy_rounded,
          semanticLabel: '$label 주소 복사',
          variant: V2IconButtonVariant.plain,
          onPressed: copy,
        ),
      ],
    );
  }
}

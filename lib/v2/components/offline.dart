// The offline line V1 showed on home, archive and reader: reading and
// records stay available on the device while the network is gone.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../design/tokens.dart';
import 'feedback.dart';

class V2OfflineNotice extends ConsumerWidget {
  const V2OfflineNotice({super.key, this.night = false});

  final bool night;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(networkConnectedProvider).value != false) {
      return const SizedBox.shrink();
    }
    final color = night ? V2Color.nightMeta : V2Color.ink2;
    return Padding(
      padding: const EdgeInsets.only(bottom: V2Space.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.cloud_off_rounded, size: 15, color: color),
              ),
            ),
            const SizedBox(width: V2Space.xs),
            Expanded(
              child: V2Meta(
                '네트워크 연결이 없어요. 기기에 저장된 기록은 계속 읽을 수 있어요.',
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

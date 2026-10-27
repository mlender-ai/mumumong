// Reading settings sheet: paper, origin marks and text size. These are the
// same device-only UiPreferences V1 uses; nothing about dreams is stored.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../design/tokens.dart';

const v2ReaderScales = [(.9, '작게'), (1.0, '보통'), (1.15, '크게'), (1.3, '더 크게')];

double nearestReaderScale(double scale) {
  var best = v2ReaderScales.first.$1;
  for (final (value, _) in v2ReaderScales) {
    if ((value - scale).abs() < (best - scale).abs()) best = value;
  }
  return best;
}

Future<void> showV2ReadingSettings(
  BuildContext context, {
  bool night = false,
}) => showV2Sheet<void>(
  context,
  night: night,
  builder: (sheetContext) => const V2ReadingSettingsPanel(),
);

/// Paper, text size and origin marks. Used by the reader sheet and the
/// settings page; values are the device-only UiPreferences.
class V2ReadingSettingsPanel extends ConsumerWidget {
  const V2ReadingSettingsPanel({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(uiPreferencesProvider);
    final night = preferences.themeMode == ThemeMode.dark;
    Future<void> save({ThemeMode? theme, double? scale, bool? origins}) async {
      final ok = await preferences.save(
        theme: theme,
        scale: scale,
        origins: origins,
      );
      if (!ok && context.mounted) {
        showV2Toast(context, '읽기 설정을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    }

    final ink = night ? V2Color.nightInk : V2Color.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text('읽기 설정', style: V2Type.title.copyWith(color: ink)),
          const SizedBox(height: V2Space.lg),
        ],
        V2Meta('종이', color: night ? V2Color.nightMeta : null),
        const SizedBox(height: V2Space.xs),
        V2Segmented<bool>(
          segments: const [(false, '낮의 종이'), (true, '밤의 종이')],
          value: night,
          onChanged: (value) =>
              save(theme: value ? ThemeMode.dark : ThemeMode.light),
        ),
        const SizedBox(height: V2Space.lg),
        V2Meta('글자 크기', color: night ? V2Color.nightMeta : null),
        const SizedBox(height: V2Space.xs),
        V2Segmented<double>(
          segments: v2ReaderScales,
          value: nearestReaderScale(preferences.readerScale),
          onChanged: (value) => save(scale: value),
        ),
        const SizedBox(height: V2Space.lg),
        V2Meta('문장의 출처', color: night ? V2Color.nightMeta : null),
        const SizedBox(height: V2Space.xs),
        V2Segmented<bool>(
          segments: const [(false, '숨기기'), (true, '여백에 표시')],
          value: preferences.showOrigins,
          onChanged: (value) => save(origins: value),
        ),
        const SizedBox(height: V2Space.sm),
        V2Meta(
          '● 꿈에서 온 문장   ○ 장면을 잇는 문장   │ 내가 쓴 문장',
          color: night ? V2Color.nightMeta : null,
        ),
      ],
    );
  }
}

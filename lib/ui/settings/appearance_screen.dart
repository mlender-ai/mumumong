import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import 'settings_components.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(uiPreferencesProvider);
    Future<void> save({ThemeMode? theme, double? scale, bool? origins}) async {
      final ok = await preferences.save(
        theme: theme,
        scale: scale,
        origins: origins,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }

    return SettingsDetailFrame(
      title: '화면과 읽기',
      description: '이 기기에 저장돼요. 원고의 내용은 바뀌지 않아요.',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SettingsGroupLabel('화면 테마'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in [
                (ThemeMode.light, '밝게'),
                (ThemeMode.dark, '어둡게'),
                (ThemeMode.system, '기기 설정'),
              ])
                ChoiceChipEditorial(
                  label: option.$2,
                  selected: preferences.themeMode == option.$1,
                  onTap: () {
                    if (!preferences.saving) save(theme: option.$1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),
          const SettingsGroupLabel('원고 글자 크기'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in [
                (0.9, '작게'),
                (1.0, '기본'),
                (1.2, '크게'),
                (1.4, '더 크게'),
              ])
                ChoiceChipEditorial(
                  label: option.$2,
                  selected: preferences.readerScale == option.$1,
                  onTap: () {
                    if (!preferences.saving) save(scale: option.$1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '한 장면이 나의 문장으로 남았다.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18 * preferences.readerScale,
            ),
          ),
          const SizedBox(height: 32),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('문단 옆 출처 표시'),
            subtitle: const Text('꿈 · 연결 · 내가 씀'),
            value: preferences.showOrigins,
            onChanged: preferences.saving
                ? null
                : (value) => save(origins: value),
          ),
          if (preferences.loadFailed)
            const Text('저장된 설정을 불러오지 못해 기본값으로 표시했어요. 설정을 다시 선택하면 저장을 재시도해요.'),
        ],
      ),
    );
  }
}

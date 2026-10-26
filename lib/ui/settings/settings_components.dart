import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';

enum SettingsDestination {
  data,
  security,
  aiProcessing,
  voiceInput,
  appearance,
  generation,
  library,
}

class SettingsOverview extends StatelessWidget {
  const SettingsOverview({super.key, required this.onOpen});

  final ValueChanged<SettingsDestination> onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: MongSpace.xl),
            children: [
              const MongPageHeader(
                title: '설정',
                description: '기록과 앱 보호 방식을 관리해요.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MongSpace.screen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsGroupLabel('나에게 맞게'),
                    SettingsNavigationRow(
                      title: '화면과 읽기',
                      subtitle: '테마 · 원고 글자 크기 · 출처 표시',
                      onTap: () => onOpen(SettingsDestination.appearance),
                    ),
                    const SizedBox(height: MongSpace.lg),
                    const SettingsGroupLabel('내 기록'),
                    SettingsNavigationRow(
                      title: '내가 완성한 책',
                      subtitle: '완성본 읽기 · PDF 저장 · 다음 권',
                      onTap: () => onOpen(SettingsDestination.library),
                    ),
                    SettingsNavigationRow(
                      title: '이후 장면 설정',
                      subtitle: '각색 · 문체 · 시점 · 기존 원고는 그대로',
                      onTap: () => onOpen(SettingsDestination.generation),
                    ),
                    SettingsNavigationRow(
                      title: '기록 관리',
                      subtitle: 'JSON 사본과 삭제 · PDF는 완성본에서',
                      onTap: () => onOpen(SettingsDestination.data),
                    ),
                    const SizedBox(height: MongSpace.lg),
                    const SettingsGroupLabel('보안'),
                    SettingsNavigationRow(
                      title: '앱 잠금',
                      subtitle: 'Face ID 또는 기기 암호',
                      onTap: () => onOpen(SettingsDestination.security),
                    ),
                    const SizedBox(height: MongSpace.lg),
                    const SettingsGroupLabel('사용 안내'),
                    SettingsNavigationRow(
                      title: 'AI 처리 고지',
                      subtitle: '전송 내용과 제공사 확인',
                      onTap: () => onOpen(SettingsDestination.aiProcessing),
                    ),
                    SettingsNavigationRow(
                      title: '음성 기록',
                      subtitle: '기기 내 음성 인식 안내',
                      onTap: () => onOpen(SettingsDestination.voiceInput),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsGroupLabel extends StatelessWidget {
  const SettingsGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: MetaText(label, color: context.metaInk),
  );
}

class SettingsNavigationRow extends StatelessWidget {
  const SettingsNavigationRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => MongListRow(
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    destructive: destructive,
  );
}

class SettingsDetailFrame extends StatelessWidget {
  const SettingsDetailFrame({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MongContextBar(
                  leading: MongIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: '설정으로 돌아가기',
                    onPressed: onBack,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (description != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Text(
                      description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.secondaryInk,
                      ),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

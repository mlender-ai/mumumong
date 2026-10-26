import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/design_system.dart';
import '../../data/local/data_export.dart';
import '../../data/local/local_data_control.dart';
import '../../di/providers.dart';
import '../auth/ai_consent.dart';
import 'settings_components.dart';
import 'appearance_screen.dart';
import 'generation_settings_screen.dart';
import '../library/library_screen.dart';
import '../shared/policy_link.dart';
import '../../core/design/thinking_orb.dart';
import '../shared/web_install_guide.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, SettingsDestination destination) {
    final page = switch (destination) {
      SettingsDestination.data => const _RecordManagementScreen(),
      SettingsDestination.security => const _AppLockSettingsScreen(),
      SettingsDestination.aiProcessing => const _AiProcessingSettingsScreen(),
      SettingsDestination.voiceInput =>
        kIsWeb ? const WebVoiceGuide() : const _VoiceInputSettingsScreen(),
      SettingsDestination.appearance => const AppearanceScreen(),
      SettingsDestination.generation => const GenerationSettingsScreen(),
      SettingsDestination.library => const LibraryScreen(),
    };
    Navigator.of(context).push(quietPageRoute(page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SettingsOverview(onOpen: (destination) => _open(context, destination));
}

class _RecordManagementScreen extends ConsumerStatefulWidget {
  const _RecordManagementScreen();

  @override
  ConsumerState<_RecordManagementScreen> createState() =>
      _RecordManagementScreenState();
}

class _RecordManagementScreenState
    extends ConsumerState<_RecordManagementScreen> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _export() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 기록 내보내기'),
        content: const Text(
          '꿈 원문, 작성 중인 초안, 원고와 출처 정보가 JSON 파일에 포함돼요. 공유할 곳은 다음 화면에서 직접 선택해 주세요.',
        ),
        actions: [
          MongButton.ghost(
            label: '취소',
            onPressed: () => Navigator.pop(context, false),
          ),
          MongButton.ghost(
            label: '내보내기',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _exporting = true);
    try {
      await ref.read(repositoryProvider).watchActiveVolume().first;
      final content = await exportLocalManuscript(ref.read(databaseProvider));
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: '무무몽 내 기록',
          files: [
            XFile.fromData(utf8.encode(content), mimeType: 'application/json'),
          ],
          fileNameOverrides: ['mumumong-export.json'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보내지 못했어요. 기록은 그대로 보관되어 있어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAll() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 기록 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('꿈 원문과 원고를 되돌릴 수 없게 삭제해요. 먼저 내보내기를 권해요.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '계속하려면 삭제 입력'),
            ),
          ],
        ),
        actions: [
          MongButton.ghost(
            label: '취소',
            onPressed: () => Navigator.pop(context, false),
          ),
          MongButton.ghost(
            label: '영구 삭제',
            onPressed: () =>
                Navigator.pop(context, controller.text.trim() == '삭제'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session != null) {
        final response = await client.functions.invoke(
          'delete-account',
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
        if (response.status < 200 || response.status >= 300) {
          throw StateError('remote_delete_failed');
        }
      }
      await clearLocalData(ref.read(databaseProvider));
      if (session != null) await client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모든 기록을 삭제했어요.')));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제 상태를 확인하지 못했어요. 다시 로그인해 남은 기록을 확인해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsDetailFrame(
    title: '기록 관리',
    description: '내 기록의 사본을 보관하거나, 무무몽에서 지울 수 있어요.',
    onBack: () => Navigator.pop(context),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        const _SettingsInfo(
          title: '기록은 내 것이에요',
          body: '꿈 · 원고 · 출처 · 작성 중인 초안을 JSON 파일로 내보낼 수 있어요.',
        ),
        const SizedBox(height: 20),
        _SettingsAction(
          title: _exporting ? '파일 준비 중' : '내 기록 내보내기',
          subtitle: 'JSON 사본 저장 · 꿈 원문과 초안 포함',
          onTap: _exporting ? null : _export,
        ),
        const SizedBox(height: 14),
        _SettingsAction(
          title: _deleting ? '삭제 중' : '모든 기록 삭제',
          subtitle: '계정이 있으면 서버 기록과 계정도 함께 삭제',
          destructive: true,
          onTap: _deleting ? null : _deleteAll,
        ),
      ],
    ),
  );
}

class _AppLockSettingsScreen extends ConsumerWidget {
  const _AppLockSettingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    return SettingsDetailFrame(
      title: '앱 잠금',
      description: '이 기기를 잠시 비울 때도 꿈과 원고를 보호해요.',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          _SettingsInfo(
            title: lock.enabled ? '잠금이 켜져 있어요' : '잠금이 꺼져 있어요',
            body: 'Face ID 또는 기기 암호로 앱을 열 수 있어요. 인증 정보는 기기 밖으로 전송되지 않아요.',
          ),
          const SizedBox(height: 20),
          MongSwitchRow(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MongRadius.field),
              side: BorderSide(color: context.hairline),
            ),
            title: const Text('앱 잠금 사용'),
            subtitle: const Text('앱을 다시 열 때 기기 인증 요청'),
            value: lock.enabled,
            onChanged: lock.authenticating
                ? null
                : (value) async {
                    final changed = await lock.setEnabled(value);
                    if (!changed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('기기 인증을 완료해야 설정을 바꿀 수 있어요.'),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _AiProcessingSettingsScreen extends ConsumerStatefulWidget {
  const _AiProcessingSettingsScreen();

  @override
  ConsumerState<_AiProcessingSettingsScreen> createState() =>
      _AiProcessingSettingsScreenState();
}

class _AiProcessingSettingsScreenState
    extends ConsumerState<_AiProcessingSettingsScreen> {
  late Future<AiConsentPolicy> _policy;

  @override
  void initState() {
    super.initState();
    _policy = ref.read(aiConsentRepositoryProvider).loadPolicy();
  }

  @override
  Widget build(BuildContext context) => SettingsDetailFrame(
    title: 'AI 처리 고지',
    description: '꿈 기록이 AI 장면 생성에 사용되는 방식과 제공사를 확인해요.',
    onBack: () => Navigator.pop(context),
    child: FutureBuilder<AiConsentPolicy>(
      future: _policy,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('현재 고지를 불러오지 못했어요.'),
                      MongButton.ghost(
                        label: '다시 시도',
                        onPressed: () => setState(() {
                          _policy = ref
                              .read(aiConsentRepositoryProvider)
                              .loadPolicy();
                        }),
                      ),
                    ],
                  )
                : const ThinkingOrb(state: DreamOrbState.connecting),
          );
        }
        final policy = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          children: [
            _SettingsInfo(title: '현재 안내', body: policy.message),
            const SizedBox(height: 20),
            const SettingsGroupLabel('처리 제공사'),
            for (final provider in policy.providers)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    PolicyLink(label: '이용 약관', uri: provider.termsUrl),
                    if (provider.dataUrl case final url?)
                      PolicyLink(label: '데이터 처리 안내', uri: url),
                  ],
                ),
              ),
            MetaText('고지 버전 ${policy.version}'),
          ],
        );
      },
    ),
  );
}

class _VoiceInputSettingsScreen extends StatelessWidget {
  const _VoiceInputSettingsScreen();

  @override
  Widget build(BuildContext context) => SettingsDetailFrame(
    title: '음성 기록',
    description: '꿈을 말로 남길 때 음성이 어떻게 처리되는지 안내해요.',
    onBack: () => Navigator.pop(context),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: const [
        _SettingsInfo(
          title: '음성은 기기 안에서만',
          body: '지원하는 iPhone에서는 기기 내 음성 인식을 사용해요. 음성 파일을 저장하거나 서버로 보내지 않아요.',
        ),
        SizedBox(height: 16),
        _SettingsInfo(
          title: '직접 입력도 가능해요',
          body: '기기에서 음성 인식을 사용할 수 없다면 텍스트로 꿈을 기록할 수 있어요.',
        ),
      ],
    ),
  );
}

class _SettingsInfo extends StatelessWidget {
  const _SettingsInfo({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
        ),
      ],
    ),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
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
  Widget build(BuildContext context) => SettingsNavigationRow(
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    destructive: destructive,
  );
}

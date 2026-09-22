import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/design_system.dart';
import '../../data/local/data_export.dart';
import '../../data/local/local_data_control.dart';
import '../../di/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _exporting = true);
    try {
      // Ensure the repository has completed its initial database setup.
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim() == '삭제'),
            child: const Text('영구 삭제'),
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
      if (session != null) {
        await client.auth.signOut();
      }
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
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
        children: [
          const MetaText('MUMUMONG · SETTINGS'),
          const SizedBox(height: 16),
          Text('내 기록과 설정', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          const Text('기록의 소유자는 나'),
          const SizedBox(height: 12),
          const Text('꿈과 원고는 현재 이 기기에 저장돼요. 앱을 삭제하기 전에 기록을 내보내 주세요.'),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_exporting ? '파일 준비 중' : '내 기록 내보내기'),
            subtitle: const Text('꿈 · 원고 · 출처 · 작성 중인 초안'),
            trailing: const Icon(Icons.ios_share, size: 20),
            onTap: _exporting ? null : _export,
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('앱 잠금'),
            subtitle: const Text('Face ID 또는 기기 암호로 꿈과 원고 보호'),
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
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_deleting ? '삭제 중' : '모든 기록 삭제'),
            subtitle: const Text('계정이 있으면 서버 기록과 계정도 함께 삭제'),
            trailing: const Icon(Icons.delete_outline, size: 20),
            onTap: _deleting ? null : _deleteAll,
          ),
          const Divider(),
          const SizedBox(height: 24),
          const Text('현재 체험 버전'),
          const SizedBox(height: 12),
          const Text('장면 생성은 아직 테스트 엔진이에요. 실제 AI 생성이나 기기 간 동기화가 연결된 버전은 아니에요.'),
          const SizedBox(height: 24),
          const Text('음성 기록'),
          const SizedBox(height: 12),
          const Text(
            '지원하는 iPhone에서만 기기 안의 음성 인식을 사용해요. 음성 파일을 저장하거나 서버로 보내지 않아요. 사용할 수 없는 기기에서는 직접 입력해 주세요.',
          ),
        ],
      ),
    );
  }
}

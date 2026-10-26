import 'package:flutter/material.dart';
import '../../core/design/design_system.dart';
import '../settings/settings_components.dart';

// Installation guidance is retired. Keep voice help separate from the native
// recorder; an installed web app does not acquire on-device speech recognition.
class WebVoiceGuide extends StatelessWidget {
  const WebVoiceGuide({super.key});
  @override
  Widget build(BuildContext context) => SettingsDetailFrame(
    title: '음성 기록 안내',
    onBack: () => Navigator.pop(context),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text('기기 안에서만 인식해요.', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        const Text(
          '무무몽 녹음은 네이티브 iPhone 앱의 온디바이스 기능이에요. 이 웹 체험판에서는 사용할 수 없어요. 홈 화면에 설치해도 iPhone 앱의 녹음 기능이 생기지는 않아요.',
        ),
        const SizedBox(height: 24),
        const Text(
          '웹에서는 직접 적거나 키보드에 음성 입력 버튼이 있으면 사용할 수 있어요. 키보드 받아쓰기는 무무몽 녹음과 다른 iOS 기능이며, 처리는 기기의 받아쓰기 설정을 따라요.',
        ),
        const SizedBox(height: 24),
        const Text('무무몽이 브라우저 마이크를 켜거나 음성을 서버로 보내지는 않아요. 작성 중인 내용은 그대로 유지돼요.'),
        const SizedBox(height: 32),
        MongActionGroup(
          primary: EditorialButton(
            label: '기록으로 돌아가기',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  );
}

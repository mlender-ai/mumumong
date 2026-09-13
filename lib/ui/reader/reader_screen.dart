import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design_system.dart';

enum PassageOrigin { dream, connection, user }

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, this.initialNight = false});

  final bool initialNight;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late bool _night = widget.initialNight;
  bool _showOrigins = true;

  Color get _paper => _night ? MongColor.nightPaper : MongColor.paper;
  Color get _ink => _night ? MongColor.nightInk : MongColor.ink;
  Color get _meta => _night ? MongColor.nightMeta : MongColor.ink3;
  Color get _line => _night ? MongColor.ink2 : MongColor.line;

  void _setSystemStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _night ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _paper,
        systemNavigationBarIconBrightness: _night
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setSystemStyle());
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: MongColor.paper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _showSource(PassageOrigin origin) {
    final isDream = origin == PassageOrigin.dream;
    final isUser = origin == PassageOrigin.user;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _night ? MongColor.nightShade : MongColor.paperPure,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 2,
                    color: _night ? MongColor.ink2 : MongColor.line,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  isDream ? '꿈에서' : (isUser ? '내가 씀' : '연결'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: _ink),
                ),
                const SizedBox(height: 7),
                Text(
                  isDream
                      ? '9월 13일 기록한 꿈'
                      : (isUser
                            ? '직접 쓴 문장은 원고에서 잠겨져요.'
                            : '2장의 붉은 문과 오늘의 문을 잇는 문장'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: _meta),
                ),
                const SizedBox(height: 24),
                if (isDream) ...[
                  Text(
                    '원문 발췌',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: _meta),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.75,
                        color: _ink,
                      ),
                      children: [
                        const TextSpan(text: '복도 바닥에 물이 차 있었고, '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: ColoredBox(
                            color: _night
                                ? MongColor.sky700.withValues(alpha: .32)
                                : MongColor.sky100,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Text('끝에 붉은 문이 있었다.'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  QuietTextButton(label: '원문 전체 보기', onPressed: () {}),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, size: 20, color: _ink),
                    tooltip: '닫기',
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Row(
                      children: [
                        MetaText('VOL.01', color: _meta),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '이름 없는 원고',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: _meta),
                          ),
                        ),
                        MetaText('p.23', color: _meta),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: _night ? MongColor.nightShade : MongColor.paperPure,
                    surfaceTintColor: Colors.transparent,
                    icon: Icon(Icons.more_horiz, color: _ink),
                    onSelected: (value) {
                      if (value == 'origin') {
                        setState(() => _showOrigins = !_showOrigins);
                      }
                      if (value == 'night') {
                        setState(() => _night = !_night);
                        _setSystemStyle();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'origin',
                        child: Text(_showOrigins ? '출처 표시 끄기' : '출처 표시 켜기'),
                      ),
                      PopupMenuItem(
                        value: 'night',
                        child: Text(_night ? '낮의 종이로 읽기' : '밤의 종이로 읽기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: _line),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: _meta),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '붉은 문',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: _ink),
                    ),
                    const SizedBox(height: 28),
                    ReaderPassage(
                      origin: PassageOrigin.dream,
                      showOrigin: _showOrigins,
                      ink: _ink,
                      meta: _meta,
                      text:
                          '복도는 생각보다 길었다. 발밑의 물은 발목까지 차 있었고, 걸음을 옮길 때마다 어딜가서 작은 종소리가 났다.',
                      onTap: () => _showSource(PassageOrigin.dream),
                    ),
                    ReaderPassage(
                      origin: PassageOrigin.connection,
                      showOrigin: _showOrigins,
                      ink: _ink,
                      meta: _meta,
                      text:
                          '그 문은 2장에서 본 적 있는 색이었다. 가까이 갈수록 붉은 색은 물 위로 번져, 복도 전체가 느리게 밝아졌다.',
                      onTap: () => _showSource(PassageOrigin.connection),
                    ),
                    ReaderPassage(
                      origin: PassageOrigin.dream,
                      showOrigin: _showOrigins,
                      ink: _ink,
                      meta: _meta,
                      text:
                          '우산을 든 여자가 문 옆에 서 있었다. 여자는 고개를 들지 않은 채 손잡이를 세 번 두드렸다.',
                      onTap: () => _showSource(PassageOrigin.dream),
                    ),
                    ReaderPassage(
                      origin: PassageOrigin.user,
                      showOrigin: _showOrigins,
                      ink: _ink,
                      meta: _meta,
                      text: '나는 그 소리가 안에서 나는 것이 아니라는 걸 알고 있었다.',
                      onTap: () => _showSource(PassageOrigin.user),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        '·',
                        style: TextStyle(fontSize: 22, color: _meta),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ReaderPassage(
                      origin: PassageOrigin.dream,
                      showOrigin: _showOrigins,
                      ink: _ink,
                      meta: _meta,
                      text: '문틈으로 물소리가 새어 나오고 있었다.',
                      onTap: () => _showSource(PassageOrigin.dream),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReaderPassage extends StatelessWidget {
  const ReaderPassage({
    super.key,
    required this.origin,
    required this.showOrigin,
    required this.ink,
    required this.meta,
    required this.text,
    required this.onTap,
  });

  final PassageOrigin origin;
  final bool showOrigin;
  final Color ink;
  final Color meta;
  final String text;
  final VoidCallback onTap;

  String get _mark => switch (origin) {
    PassageOrigin.dream => '●',
    PassageOrigin.connection => '○',
    PassageOrigin.user => '│',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              origin == PassageOrigin.user
                  ? '내가 쓴 문장은 잠겨져 있어요.'
                  : '편집 모드를 준비했어요.',
            ),
            backgroundColor: MongColor.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: MongMotion.base,
              width: showOrigin ? 25 : 0,
              padding: const EdgeInsets.only(top: 5),
              child: showOrigin
                  ? Text(_mark, style: TextStyle(fontSize: 10, color: meta))
                  : null,
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

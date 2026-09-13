import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'archive_screen.dart';
import 'capture_flow.dart';
import 'design_system.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: MongColor.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MumumongApp());
}

class MumumongApp extends StatelessWidget {
  const MumumongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '무무몽',
      theme: mumumongTheme(),
      home: const MumumongShell(),
    );
  }
}

class MumumongShell extends StatefulWidget {
  const MumumongShell({super.key});

  @override
  State<MumumongShell> createState() => _MumumongShellState();
}

class _MumumongShellState extends State<MumumongShell> {
  int _tab = 0;
  double _progress = .42;
  int _dreams = 7;
  int _scenes = 11;
  bool _showGrowth = false;

  Future<void> _openCapture() async {
    final created = await Navigator.of(context).push<bool>(
      quietPageRoute(
        CaptureFlow(dreamNumber: _dreams + 1, sceneNumber: _scenes + 1),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _progress = (_progress + .06).clamp(0, 1);
        _dreams += 1;
        _scenes += 1;
        _showGrowth = true;
        _tab = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        progress: _progress,
        dreams: _dreams,
        scenes: _scenes,
        animateGrowth: _showGrowth,
        onGrowthFinished: () {
          if (mounted) setState(() => _showGrowth = false);
        },
        onCapture: _openCapture,
      ),
      ArchiveScreen(includeNewDream: _dreams > 7, onCapture: _openCapture),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: MongColor.paper,
          border: Border(top: BorderSide(color: MongColor.line, width: .5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _BottomTab(
                  label: '원고',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _BottomTab(
                  label: '보관함',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: MongMotion.micro,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected ? MongColor.ink : MongColor.ink3,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

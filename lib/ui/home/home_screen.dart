import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dot_field.dart';
import '../reader/reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.progress,
    required this.dreams,
    required this.scenes,
    required this.animateGrowth,
    required this.onGrowthFinished,
    required this.onCapture,
  });

  final double progress;
  final int dreams;
  final int scenes;
  final bool animateGrowth;
  final VoidCallback onGrowthFinished;
  final VoidCallback onCapture;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _growthController;

  @override
  void initState() {
    super.initState();
    _growthController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3000),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onGrowthFinished();
        });
    if (widget.animateGrowth) _growthController.forward();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateGrowth && !oldWidget.animateGrowth) {
      _growthController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growthController.dispose();
    super.dispose();
  }

  void _openReader() {
    Navigator.of(context).push(quietPageRoute(const ReaderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverWidth = (constraints.maxWidth - 96).clamp(220.0, 292.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [MetaText('VOL.01'), MetaText('SEP 13 2026')],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: _openReader,
                      child: SizedBox(
                        width: coverWidth,
                        child: AnimatedBuilder(
                          animation: _growthController,
                          builder: (context, _) {
                            final value = !widget.animateGrowth || reduceMotion
                                ? 1.0
                                : MongMotion.form.transform(
                                    (_growthController.value / .5).clamp(0, 1),
                                  );
                            return DotCover(
                              clarity: .10 + .70 * widget.progress,
                              growth: value,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '이름 없는 원고',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _growthController,
                        builder: (context, _) {
                          final completed = (widget.progress * 100).round();
                          final shown = widget.animateGrowth && !reduceMotion
                              ? (completed -
                                        6 +
                                        6 *
                                            Curves.easeOut.transform(
                                              _growthController.value,
                                            ))
                                    .round()
                              : completed;
                          return Text(
                            '$shown%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontSize: 15, color: MongColor.ink),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MetaText(
                    '${widget.dreams} dreams     ${widget.scenes} scenes     약 35p',
                  ),
                  AnimatedSize(
                    duration: MongMotion.base,
                    alignment: Alignment.topCenter,
                    child: widget.animateGrowth
                        ? const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                MetaText('오늘', color: MongColor.ink3),
                                SizedBox(width: 18),
                                MetaText('새 장면 1', color: MongColor.ink),
                                SizedBox(width: 18),
                                MetaText('연결 1 확정', color: MongColor.ink),
                                Spacer(),
                                MetaText('+6%', color: MongColor.ink),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Text(
                    '미스터리와 초현실의 성격이 보여요.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: EditorialButton(
                          label: '꿈 기록하기',
                          onPressed: widget.onCapture,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: EditorialButton(
                          label: '이어 읽기',
                          onPressed: _openReader,
                          dark: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _openReader,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 42,
                            margin: const EdgeInsets.only(right: 14, top: 2),
                            color: MongColor.sky500,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MetaText('열린 장면'),
                                const SizedBox(height: 5),
                                Text(
                                  '문틈으로 물소리가 새어 나오고 있었다.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: MongColor.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

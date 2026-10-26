// Explicit component review. Never used to report production job progress.
import 'package:flutter/material.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';

class OrbMotionReview extends StatefulWidget {
  const OrbMotionReview({super.key});
  @override
  State<OrbMotionReview> createState() => _OrbMotionReviewState();
}

class _OrbMotionReviewState extends State<OrbMotionReview> {
  orbs.OrbState _state = orbs.OrbState.working;
  bool _paused = false;
  bool _night = false;
  double _speed = 1;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Theme(
      data: _night ? dreamNightTheme() : mumumongTheme(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.canvas,
          appBar: AppBar(
            title: const Text('Orb 모션 보기'),
            backgroundColor: context.canvas,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 128,
                        child: Center(
                          child: RepaintBoundary(
                            key: const Key('orb-review-animation'),
                            child: orbs.ThinkingOrb(
                              state: _state,
                              size: orbs.OrbSize.size64,
                              color: _night
                                  ? const Color(0xFFC8E6FA)
                                  : MongColor.orbInk,
                              speed: _speed,
                              paused: _paused,
                              semanticLabel: '${_state.name} 모션',
                            ),
                          ),
                        ),
                      ),
                      Text(
                        _state.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const MetaText(
                                'COMPONENT REVIEW · 실제 생성 작업이 아니에요',
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Libraries.dev의 9개 상태를 Flutter 포트로 표시합니다. 진행률이나 네트워크 요청은 없어요.',
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final state in orbs.OrbState.values)
                                    ChoiceChipEditorial(
                                      label: state.name,
                                      selected: state == _state,
                                      onTap: () =>
                                          setState(() => _state = state),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '속도 ${_speed.toStringAsFixed(1)}×',
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: reduced
                                        ? null
                                        : () => setState(
                                            () => _paused = !_paused,
                                          ),
                                    icon: Icon(
                                      _paused
                                          ? Icons.play_arrow_rounded
                                          : Icons.pause_rounded,
                                    ),
                                    label: Text(_paused ? '재생' : '일시 정지'),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _speed,
                                min: .5,
                                max: 1.5,
                                divisions: 4,
                                semanticFormatterCallback: (value) =>
                                    '${value.toStringAsFixed(1)}배속',
                                onChanged: reduced
                                    ? null
                                    : (value) => setState(() => _speed = value),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('어두운 바탕에서 보기'),
                                value: _night,
                                onChanged: (value) =>
                                    setState(() => _night = value),
                              ),
                              if (reduced)
                                const Text(
                                  '기기에서 동작 줄이기가 켜져 있어 정지 프레임으로 표시합니다.',
                                ),
                              const SizedBox(height: 24),
                              const MetaText(
                                '64px 원본 규격 · thinking_orbs 0.2.0 · leofmarciano Flutter 포트. 원본 React 코드를 그대로 실행한 화면은 아닙니다.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassActionButton(
                        label: '이전 화면으로',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

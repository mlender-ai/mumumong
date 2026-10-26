import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';
import '../../core/design/thinking_orb.dart';

/// A real network wait, never a simulated step or progress percentage.
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({
    super.key,
    required this.title,
    this.orbState = DreamOrbState.connecting,
  });

  final String title;
  final DreamOrbState orbState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: context.canvas,
        child: SafeArea(
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: title,
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: ThinkingOrb(
                      state: orbState,
                      color: context.isNight
                          ? MongColor.nightSky
                          : MongColor.orbInk,
                    ),
                  ),
                  const SizedBox(height: MongSpace.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

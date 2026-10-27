// Screens not yet redrawn in V2 (completed books, completion request) open
// through this bridge. It keeps the V1 theme on every page they push, and a
// pop of their first page closes the bridge, so their code runs unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import '../design/theme.dart';

Future<void> openInV1(BuildContext context, Widget screen) =>
    Navigator.of(context).push(v2Route(V1Bridge(child: screen)));

class V1Bridge extends ConsumerStatefulWidget {
  const V1Bridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<V1Bridge> createState() => _V1BridgeState();
}

class _V1BridgeState extends ConsumerState<V1Bridge> {
  final _inner = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Starting the next volume returns V1 to its first route. Here that
    // means leaving the bridge and every page under it as well.
    ref.listenManual(libraryReturnHomeProvider, (_, _) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  /// Closes this bridge's own route. A direct pop, not maybePop: the pop
  /// handler below makes the bridge route refuse maybePop while the inner
  /// navigator can pop, which is exactly the case this runs in.
  void _exit() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: mumumongTheme(),
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _inner.currentState?.maybePop(),
        child: HeroControllerScope.none(
          child: Navigator(
            key: _inner,
            onGenerateInitialRoutes: (_, _) => [
              _BridgeRoot<void>(onExit: _exit, builder: (_) => widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bridge's first page. It holds one local-history entry, so a pop of
/// this page (a V1 back button, or system back) is handled here and closes
/// the bridge route instead of leaving the inner navigator empty.
class _BridgeRoot<T> extends PageRouteBuilder<T> {
  _BridgeRoot({required this.onExit, required WidgetBuilder builder})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  final VoidCallback onExit;

  @override
  void install() {
    super.install();
    addLocalHistoryEntry(
      LocalHistoryEntry(impliesAppBarDismissal: false, onRemove: onExit),
    );
  }
}

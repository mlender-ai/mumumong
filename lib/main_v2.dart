// MUMUMONG V2 PREVIEW entry point (redesign/mumumong-v2 only).
//
//   flutter run -t lib/main_v2.dart --dart-define=ENV=dev --dart-define=ENGINE=mock
//
// The preview refuses to start with anything but ENV=dev and ENGINE=mock, so
// it can never reach a hosted backend or production AI. lib/main.dart (V1)
// is unchanged and still builds the current app.
import 'package:flutter/material.dart';

import 'core/env/env.dart';
import 'v2/design/theme.dart';
import 'v2/design/tokens.dart';
import 'v2/preview/preview_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final previewOnly =
      AppEnv.environment == AppEnvironment.dev &&
      AppEnv.engine == EngineMode.mock;
  runApp(previewOnly ? const V2PreviewRoot() : const _PreviewRefused());
}

class _PreviewRefused extends StatelessWidget {
  const _PreviewRefused();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: v2Theme(),
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(V2Space.gutter),
          child: Text(
            'V2 미리보기는 ENV=dev, ENGINE=mock 에서만 실행돼요.',
            textAlign: TextAlign.center,
            style: V2Type.headline,
          ),
        ),
      ),
    ),
  );
}

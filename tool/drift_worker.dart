// Match the worker to pubspec.lock instead of shipping an older downloaded JS.
// Canonical entry point: drift/web/drift_worker.dart (MIT).
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();

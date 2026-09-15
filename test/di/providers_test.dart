import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';

void main() {
  test('repositoryProvider defaults to DriftRepository', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(repositoryProvider), isA<DriftRepository>());
  });
}

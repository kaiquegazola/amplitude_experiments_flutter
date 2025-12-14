import 'package:amplitude_experiments_flutter/amplitude_experiments_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize test', (WidgetTester tester) async {
    // Test that initialize completes without throwing
    // Note: This will fail without a valid deployment key in a real test
    expect(() => AmplitudeExperiments.initialize('test-key'), returnsNormally);
  });

  testWidgets('all variants returns map', (WidgetTester tester) async {
    // After initialization, all() should return a map (possibly empty)
    final variants = await AmplitudeExperiments.all();
    expect(variants, isA<Map<String, Variant>>());
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:freflutter/app/app.dart';
import 'package:freflutter/core/di/injection.dart';

void _mockPathProvider() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async => '.',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  _mockPathProvider();

  setUp(() async {
    await GetStorage.init();
    await getIt.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreApp());
    await tester.pumpAndSettle();

    expect(find.text('FreshOrder'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

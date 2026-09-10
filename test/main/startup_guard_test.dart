import 'package:flutter_test/flutter_test.dart';
import 'package:misty_breez/main/startup_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    startedWithoutSdk = false;
  });

  test('skips connecting once after two launches died during startup', () async {
    expect(await shouldConnectOnStartup(), isTrue);
    expect(await shouldConnectOnStartup(), isTrue);

    expect(await shouldConnectOnStartup(), isFalse);
    expect(startedWithoutSdk, isTrue);

    expect(await shouldConnectOnStartup(), isTrue, reason: 'the next launch tries again');
  });

  test('launches that survived startup do not count', () async {
    for (int i = 0; i < 3; i++) {
      expect(await shouldConnectOnStartup(), isTrue);
      await markLaunchFinished();
    }
    expect(startedWithoutSdk, isFalse);
  });
}

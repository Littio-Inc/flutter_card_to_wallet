import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_card_to_wallet/flutter_card_to_wallet.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_card_to_wallet');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterCardToWallet.platformVersion, '42');
  });
}

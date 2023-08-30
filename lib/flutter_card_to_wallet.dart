
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterCardToWallet {
  static const MethodChannel _channel = MethodChannel('flutter_card_to_wallet');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

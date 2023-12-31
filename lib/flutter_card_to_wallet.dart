import 'dart:async';

import 'package:flutter/services.dart';

export 'widgets/card_to_wallet_button.dart';

class FlutterCardToWallet {
  static const MethodChannel _channel = MethodChannel('flutter_card_to_wallet');

  static final FlutterCardToWallet _instance = FlutterCardToWallet._internal();

  /// Associate each rendered Widget to its `onPressed` event handler
  static final Map<String, FutureOr<dynamic> Function(MethodCall)> _handlers =
      {};

  factory FlutterCardToWallet() {
    return _instance;
  }

  FlutterCardToWallet._internal() {
    _initMethodCallHandler();
  }

  void _initMethodCallHandler() => _channel.setMethodCallHandler(_handleCalls);

  Future<dynamic> _handleCalls(MethodCall call) async {
    var handler = _handlers[call.arguments['key']];
    return handler != null ? await handler(call) : null;
  }

  Future<void> addHandler<T>(
      String key, FutureOr<T> Function(MethodCall) handler) async {
    _handlers[key] = handler;
  }

  void removeHandler(String key) {
    _handlers.remove(key);
  }
}
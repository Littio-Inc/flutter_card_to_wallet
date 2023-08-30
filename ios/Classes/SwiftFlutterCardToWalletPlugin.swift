import Flutter
import UIKit
import PassKit

public class SwiftFlutterCardToWalletPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_card_to_wallet", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCardToWalletPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
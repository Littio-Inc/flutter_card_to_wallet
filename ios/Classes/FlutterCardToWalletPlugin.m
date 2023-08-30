#import "FlutterCardToWalletPlugin.h"
#if __has_include(<flutter_card_to_wallet/flutter_card_to_wallet-Swift.h>)
#import <flutter_card_to_wallet/flutter_card_to_wallet-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_card_to_wallet-Swift.h"
#endif

@implementation FlutterCardToWalletPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCardToWalletPlugin registerWithRegistrar:registrar];
}
@end

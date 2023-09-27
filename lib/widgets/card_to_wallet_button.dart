import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_to_wallet/flutter_card_to_wallet.dart';


class AddToWalletButton extends StatefulWidget {
  static const viewType = 'PKAddPassButton';

  final Widget? unsupportedPlatformChild;
  final String _id = UniqueKey().toString();
  final FutureOr<dynamic> Function(dynamic)? onPressButton;
  final String cardId;
  final String holder;
  final String panTokenSufix;
  final String host;
  final String token;

  AddToWalletButton({
    Key? key,
    required this.cardId,
    required this.holder,
    required this.panTokenSufix,
    required this.host,
    required this.token,
    this.onPressButton,
    this.unsupportedPlatformChild,
  }) : super(key: key);

  @override
  _AddToWalletButtonState createState() => _AddToWalletButtonState();
}

class _AddToWalletButtonState extends State<AddToWalletButton> {

  final width = 150.0;
  final height = 80.0;

  get uiKitCreationParams => {
        'cardId': widget.cardId,
        'holder': widget.holder,
        'panTokenSufix': widget.panTokenSufix,
        'key': widget._id,
        'width': width,
        'height': height,
        'host': widget.host,
        'token': widget.token,
      };

  @override
  void initState() {
    super.initState();
    FlutterCardToWallet().addHandler(widget._id, (methodCall) async {
      if(widget.onPressButton != null) {
        await widget.onPressButton!(methodCall.arguments);
      }
    });
  }

  @override
  void dispose() {
    FlutterCardToWallet().removeHandler(widget._id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return platformWidget(context);
  }

  Widget platformWidget(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return SizedBox(
          width: width,
          height: height,
          child: UiKitView(
            viewType: AddToWalletButton.viewType,
            layoutDirection: Directionality.of(context),
            creationParams: uiKitCreationParams,
            creationParamsCodec: const StandardMessageCodec(),
          ),
        );
      default:
        if (widget.unsupportedPlatformChild == null) {
          throw UnsupportedError('Unsupported platform view');
        }
        return widget.unsupportedPlatformChild!;
    }
  }
}

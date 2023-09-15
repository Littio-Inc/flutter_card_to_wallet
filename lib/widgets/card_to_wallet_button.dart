import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_to_wallet/flutter_card_to_wallet.dart';

class IssuerRequest {
  final List<dynamic> certificates;
  final String nonce;
  final String nonceSignature;
  final String cardId;

  IssuerRequest({
    required this.certificates,
    required this.nonce,
    required this.nonceSignature,
    required this.cardId,
  });

  toJson() {
    return {
      "certificates": certificates,
      "nonce": nonce,
      "nonceSignature": nonceSignature,
      "cardId": cardId,
    };
  }
}

class IssuerResponse {
  final String activationData;
  final String ephemeralPublicKey;
  final String encryptedPassData;

  IssuerResponse({
    required this.activationData,
    required this.ephemeralPublicKey,
    required this.encryptedPassData,
  });

  toJson() {
    return {
      "activationData": activationData,
      "ephemeralPublicKey":ephemeralPublicKey,
      "encryptedPassData": encryptedPassData,
    };
  }
}

class AddToWalletButton extends StatefulWidget {
  static const viewType = 'PKAddPassButton';

  final Widget? unsupportedPlatformChild;
  final FutureOr<void> Function()? onPressed;
  final String _id = "13131";
  final FutureOr<IssuerResponse?> Function(IssuerRequest) onPressButton;
  final String cardId;
  final String holder;
  final String panTokenSufix;

  const AddToWalletButton({
    Key? key,
    required this.cardId,
    required this.holder,
    required this.onPressButton,
    required this.panTokenSufix,
    this.onPressed,
    this.unsupportedPlatformChild,
  }) : super(key: key);

  @override
  _AddToWalletButtonState createState() => _AddToWalletButtonState();
}

class _AddToWalletButtonState extends State<AddToWalletButton> {
  get uiKitCreationParams => {
        'cardId': widget.cardId,
        'holder': widget.holder,
        'panTokenSufix': widget.panTokenSufix,
        'key': widget._id,
        'width': 100,
        'height': 100,
      };

  @override
  void initState() {
    super.initState();
    FlutterCardToWallet().addHandler(widget._id, (methodCall) async {
      print("ACACACA111");
      print(methodCall.arguments);
      final response = await widget.onPressButton(methodCall.arguments);
      return response?.toJson();
    });
  }

  @override
  void dispose() {
    FlutterCardToWallet().removeHandler(widget._id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: platformWidget(context),
    );
  }

  Widget platformWidget(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: AddToWalletButton.viewType,
          layoutDirection: Directionality.of(context),
          creationParams: uiKitCreationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        if (widget.unsupportedPlatformChild == null) {
          throw UnsupportedError('Unsupported platform view');
        }
        return widget.unsupportedPlatformChild!;
    }
  }
}

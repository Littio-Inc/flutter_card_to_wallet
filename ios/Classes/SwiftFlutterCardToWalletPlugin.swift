import Flutter
import UIKit
import PassKit
import Foundation

enum AddToWalletEvent: String {
    case addButtonPressed = "add_button_pressed"
}

class PKAddPassButtonNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger, channel: FlutterMethodChannel) {
        self.messenger = messenger
        self.channel = channel
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let buttonArgs = args as! [String: Any]
        let viewController = ViewController(
            key: buttonArgs["key"] as! String,
            channel: channel,
            cardId: buttonArgs["cardId"] as! String,
            cardData: Card(panTokenSuffix: buttonArgs["panTokenSufix"] as! String, holder: buttonArgs["holder"] as! String)
        )
        return PKAddPassButtonNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: buttonArgs,
            binaryMessenger: messenger,
            channel: channel,
            viewController: viewController
        )
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PKAddPassButtonNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _key: String
    private var _channel: FlutterMethodChannel
    private var _viewController: ViewController

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String: Any],
        binaryMessenger messenger: FlutterBinaryMessenger?,
        channel: FlutterMethodChannel,
        viewController: ViewController
    ) {
        _key = args["key"] as! String
        _channel = channel
        _viewController = viewController
        _view = _viewController.view
        super.init()
    }

    func view() -> UIView {
        _view
    }

    // func createAddPassButton() {
    //     let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
    //     passButton.frame = CGRect(x: 0, y: 0, width: _width, height: _height)
    //     passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
    //     _view.addSubview(passButton)
    // }

    // @objc func passButtonAction() {
    //   _invokeAddButtonPressed()
    //   guard isPassKitAvailable() else {
    //     return
    //   }
    //   initEnrollProcess()
    // }
    
    // func _invokeAddButtonPressed() {
    //     NSLog("INVOKE FROM SWIFT")
    //     _channel.invokeMethod(AddToWalletEvent.addButtonPressed.rawValue, arguments: ["key": _key])
    // }
    
}

// public class SwiftFlutterCardToWalletPlugin: NSObject, FlutterPlugin {
//   public static func register(with registrar: FlutterPluginRegistrar) {
//     let channel = FlutterMethodChannel(name: "flutter_card_to_wallet", binaryMessenger: registrar.messenger())
//     let instance = SwiftFlutterCardToWalletPlugin()
//     let factory = PKAddPassButtonNativeViewFactory(messenger: registrar.messenger(), channel: channel)
//     registrar.register(factory, withId: "PKAddPassButton")
//     registrar.addMethodCallDelegate(instance, channel: channel)
//   }

//     public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//         return result(FlutterMethodNotImplemented)
//     }
// }

public class SwiftFlutterCardToWalletPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // let channel = FlutterMethodChannel(name: "flutter_card_to_wallet", binaryMessenger: registrar.messenger())
    // let instance = SwiftFlutterCardToWalletPlugin()
    // registrar.addMethodCallDelegate(instance, channel: channel)

    let channel = FlutterMethodChannel(name: "flutter_card_to_wallet", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCardToWalletPlugin()
    let factory = PKAddPassButtonNativeViewFactory(messenger: registrar.messenger(), channel: channel)
    registrar.register(factory, withId: "PKAddPassButton")
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    return result(FlutterMethodNotImplemented)
  }
}

struct Card {
  let panTokenSuffix: String
  let holder: String
}


class ViewController: UIViewController {

    private var _key: String
    private var _channel: FlutterMethodChannel
    private var _cardId: String
    private var _cardData: Card

    init(
        key: String,
        channel: FlutterMethodChannel,
        cardId: String,
        cardData: Card
    ) {
        self._key = key
        self._channel = channel
        self._cardId = cardId
        self._cardData = cardData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad() 
        setupApplePayButton()
    }
    
    private func setupApplePayButton() {
        let passKitButton = PKAddPassButton(addPassButtonStyle: .blackOutline)
        passKitButton.addTarget(self, action: #selector(onEnroll), for: .touchUpInside)
        view.addSubview(passKitButton)
        passKitButton.translatesAutoresizingMaskIntoConstraints = false
        passKitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        passKitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
    }
    
    @objc private func onEnroll(button: UIButton) {
        guard isPassKitAvailable() else {
            showPassKitUnavailable(message: "Apple Pay is not available for your device")
            return
        }
        initEnrollProcess()
    }

    private func isPassKitAvailable() -> Bool {
        return PKAddPaymentPassViewController.canAddPaymentPass()
    }

    private func initEnrollProcess() {
        print("INIT ENROLL")
        guard let configuration = PKAddPaymentPassRequestConfiguration( encryptionScheme: .ECC_V2) else {
            showPassKitUnavailable(message: "Apple Pay no está disponible para tu dispositivo por el momento")
            return
        }
        configuration.cardholderName = _cardData.holder
        configuration.primaryAccountSuffix = _cardData.panTokenSuffix
        print("CARD HOLDER")
        print(_cardData.holder)
        guard let enrollViewController = PKAddPaymentPassViewController(
            requestConfiguration: configuration,
            delegate: self
        ) else {
            showPassKitUnavailable(message: "Apple Pay no está disponible para tu dispositivo. Ocurrió un error al configurarlo")
            return
        }
        present(enrollViewController, animated: true, completion: nil)
    }

    public func showPassKitUnavailable(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: PKAddPaymentPassViewControllerDelegate {
  // Listener para contactar al backend y obtener la información generada por Pomelo.
  func addPaymentPassViewController(
    _ controller: PKAddPaymentPassViewController,
    generateRequestWithCertificateChain certificates: [Data],
    nonce: Data,
    nonceSignature: Data,
    completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void
  ) {
        // Contactamos al backend, con la información provista por Apple.
        let request = IssuerRequest(
            certificates: certificates,
            nonce: nonce,
            nonceSignature: nonceSignature,
            cardId: self._cardId
        )
        let interactor = GetPassKitDataIssuerHostInteractor(
            key: self._key,
            viewController: self
        )
        interactor.execute(channel: _channel, request: request) { response in
            let requestCard = PKAddPaymentPassRequest()
            requestCard.activationData = response.activationData
            requestCard.ephemeralPublicKey = response.ephemeralPublicKey
            requestCard.encryptedPassData = response.encryptedPassData
            handler(requestCard)
        }
  }
  // Listener sobre el resultado de aprovisionamiento
  func addPaymentPassViewController(
    _ controller: PKAddPaymentPassViewController,
    didFinishAdding pass: PKPaymentPass?,
    error: Error?
  ) {
    if let _ = pass {
        print("Se pudo agregar la tarjeta a Apple Pay")
    } else {
        print("Ocurrió un error y no se pudo agregar la tarjeta a Apple Pay")
    }
  }
}

struct IssuerRequest {
  let certificates: [Data]
  let nonce: Data
  let nonceSignature: Data
  let cardId: String
}

struct IssuerResponse {
  let activationData: Data
  let ephemeralPublicKey: Data
  let encryptedPassData: Data
}

private class GetPassKitDataIssuerHostInteractor {

    private let _key: String
    private let _viewController: ViewController

    init(key: String, viewController: ViewController) {
        self._key = key
        self._viewController = viewController
    }

    func execute(
        channel: FlutterMethodChannel,
        request: IssuerRequest,
        onFinish: @escaping (IssuerResponse) -> ()
    ) {
        channel.invokeMethod(
            AddToWalletEvent.addButtonPressed.rawValue,
            arguments: [
                "key": self._key,
                "certificates": request.certificates,
                "nonce": request.nonce,
                "nonceSignature": request.nonceSignature
            ]) { res in
            if let apiResponse = res as? [String: Any],
                let activationData = apiResponse["activationData"] as? Data,
                let ephemeralPublicKey = apiResponse["ephemeralPublicKey"] as? Data,
                let encryptedPassData = apiResponse["encryptedPassData"] as? Data {
                    let response = IssuerResponse(
                        activationData: activationData,
                        ephemeralPublicKey: ephemeralPublicKey,
                        encryptedPassData: encryptedPassData
                    )
                    onFinish(response)
            } else {
               self._viewController.showPassKitUnavailable(message: "Error en la respuesta del servidor")
               return
            }
        }
        
    }
}

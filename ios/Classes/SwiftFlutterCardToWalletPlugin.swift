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
            cardData: Card(panTokenSuffix: buttonArgs["panTokenSufix"] as! String, holder: buttonArgs["holder"] as! String),
            host: buttonArgs["host"] as! String,
            token: buttonArgs["token"] as! String
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
}


public class SwiftFlutterCardToWalletPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
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
    private var _host: String
    private var _token: String

    init(
        key: String,
        channel: FlutterMethodChannel,
        cardId: String,
        cardData: Card,
        host: String,
        token: String
    ) {
        self._key = key
        self._channel = channel
        self._cardId = cardId
        self._cardData = cardData
        self._host = host
        self._token = token
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
        guard let configuration = PKAddPaymentPassRequestConfiguration( encryptionScheme: .ECC_V2) else {
            showPassKitUnavailable(message: "Apple Pay no está disponible para tu dispositivo por el momento")
            _invokeAddButtonPressed(status: "error-configuration-init")
            return
        }
        configuration.cardholderName = _cardData.holder
        configuration.primaryAccountSuffix = _cardData.panTokenSuffix
        guard let enrollViewController = PKAddPaymentPassViewController(
            requestConfiguration: configuration,
            delegate: self
        ) else {
            showPassKitUnavailable(message: "Apple Pay no está disponible para tu dispositivo. Ocurrió un error al configurarlo")
            _invokeAddButtonPressed(status: "error-configuration-enroll")
            return
        }
        _invokeAddButtonPressed(status: "start-enroll")
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

    func _invokeAddButtonPressed(status: String) {
        _channel.invokeMethod(
            AddToWalletEvent.addButtonPressed.rawValue,
            arguments: ["key": _key, "panTokenSuffix": _cardData.panTokenSuffix, "status": status]
        )
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
            host: self._host,
            token: self._token
        )
        interactor.execute(request: request) { response in
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

struct IssuerRequest: Codable {
  let certificates: [Data]
  let nonce: Data
  let nonceSignature: Data
  let cardId: String
}

struct IssuerResponse: Codable {
  let activationData: Data
  let ephemeralPublicKey: Data
  let encryptedPassData: Data
}

private class GetPassKitDataIssuerHostInteractor {
    private let _host: String
    private let _token: String

    init(host: String, token: String) {
        self._host = host
        self._token = token
    }

    func execute(request: IssuerRequest, onFinish: @escaping (IssuerResponse) -> Void) {
        // URL del host al que deseas hacer la solicitud POST
        let url = URL(string: self._host)!
        
        // Crear la solicitud URLRequest para una solicitud POST
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer " + self._token, forHTTPHeaderField: "Authorization")
        
        // Aquí puedes configurar los encabezados de la solicitud si es necesario
        
        // Puedes convertir tu objeto request en datos para enviarlo en el cuerpo de la solicitud
        let requestData = try? JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        // Crear una sesión de URLSession
        let session = URLSession.shared
        
        // Crear una tarea de solicitud de datos
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            // Comprobar si hay errores
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            // Comprobar si la respuesta es válida
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Respuesta no válida")
                return
            }
            
            // Procesar los datos recibidos (en este ejemplo, se asume que la respuesta es JSON)
            if let data = data {
                do {
                    let issuerResponse = try JSONDecoder().decode(IssuerResponse.self, from: data)
                    onFinish(issuerResponse)
                } catch {
                    print("Error al decodificar la respuesta JSON: \(error.localizedDescription)")
                }
            }
        }
        // Iniciar la tarea de solicitud
        task.resume()
    }
}

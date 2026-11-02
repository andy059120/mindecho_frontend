import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var symbolChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MindEchoSymbols")!
    symbolChannel = FlutterMethodChannel(
      name: "mindecho/system_symbols", binaryMessenger: registrar.messenger())
    symbolChannel?.setMethodCallHandler { call, result in
      guard call.method == "render",
        let args = call.arguments as? [String: Any],
        let name = args["name"] as? String,
        let size = args["size"] as? Double
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let weights: [String: UIImage.SymbolWeight] = [
        "light": .light, "regular": .regular, "medium": .medium,
        "semibold": .semibold, "bold": .bold,
      ]
      let configuration = UIImage.SymbolConfiguration(
        pointSize: size, weight: weights[args["weight"] as? String ?? "regular"] ?? .regular)
      guard let image = UIImage(systemName: name, withConfiguration: configuration)?
        .withTintColor(.white, renderingMode: .alwaysOriginal),
        let png = image.pngData()
      else {
        result(FlutterError(code: "symbol_unavailable", message: name, details: nil))
        return
      }
      result(["bytes": FlutterStandardTypedData(bytes: png),
              "width": image.size.width, "height": image.size.height])
    }
  }
}

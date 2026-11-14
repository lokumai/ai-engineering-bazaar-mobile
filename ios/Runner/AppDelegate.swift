import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Each app icon's name on the Dart side (lib/shared/app_icon/) and its alternate icon in the asset catalog; the
  /// default, noir, is the primary icon (nil).
  static let appIcons: [String: String?] = [
    "noir": nil,
    "ink": "AppIconInk",
    "nightGold": "AppIconNightGold",
    "nightSea": "AppIconNightSea",
    "dark": "AppIconDark",
    "cream": "AppIconCream",
  ]

  /// The ground of each icon, as lib/shared/app_icon/bazaar_icon.dart paints it: the opening starts on it.
  static let grounds: [String: UInt32] = [
    "noir": 0x1d1f27,
    "ink": 0xfdfbf7,
    "nightGold": 0x1d1f27,
    "nightSea": 0x16302f,
    "dark": 0x1d1f27,
    "cream": 0xfdfbf7,
  ]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // lib/infrastructure/app_icon/app_icon_channel.dart names the icon the reader chose in Settings.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BazaarAppIcon") else { return }
    FlutterMethodChannel(name: "dev.lokumai.bazaar/app_icon", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "choose" else { return result(FlutterMethodNotImplemented) }
        guard let icon = call.arguments as? String, let name = AppDelegate.appIcons[icon],
          let ground = AppDelegate.grounds[icon]
        else {
          return result(FlutterError(code: "unknown-icon", message: call.arguments as? String, details: nil))
        }
        LaunchPicture.keep(ground)
        let app = UIApplication.shared
        // The system tells the reader of every change, so an icon already in place is left alone (each launch names
        // the chosen icon again).
        guard app.supportsAlternateIcons, app.alternateIconName != name else { return result(nil) }
        app.setAlternateIconName(name) { error in
          if let error {
            NSLog("Bazaar: app icon %@ not set: %@", name ?? "default", error.localizedDescription)
          }
          result(error.map { FlutterError(code: "not-changed", message: $0.localizedDescription, details: nil) })
        }
      }
  }
}

/// iOS opens an app on a picture of its launch screen that it keeps in the app's Library/SplashBoard, and the launch
/// screen is one for every icon (the dark ground). Repainting those pictures in the chosen icon's ground lets the app
/// open on that ground from the next launch (the owner, 2026-11-14). The folder is not documented: when it is missing
/// or a picture cannot be read, nothing changes and the app opens on the dark ground as before. iOS draws the pictures
/// again after an update, and the next launch paints them again.
enum LaunchPicture {
  /// Where the ground of the icon last named is kept, for [BazaarViewController] on the next launch.
  static let groundKey = "BazaarLaunchGround"

  /// The ground of the icon last named, as a colour; nil before the Dart side first named one.
  static var kept: UIColor? {
    guard let ground = UserDefaults.standard.object(forKey: groundKey) as? Int else { return nil }
    return colour(UInt32(ground))
  }

  /// Keeps [ground] for the next launch and repaints iOS's launch pictures in it.
  static func keep(_ ground: UInt32) {
    UserDefaults.standard.set(Int(ground), forKey: groundKey)
    paint(ground)
  }

  static func colour(_ ground: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((ground >> 16) & 0xff) / 255,
      green: CGFloat((ground >> 8) & 0xff) / 255,
      blue: CGFloat(ground & 0xff) / 255,
      alpha: 1)
  }

  static func paint(_ ground: UInt32) {
    DispatchQueue.global(qos: .utility).async {
      guard let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first,
        let bundle = Bundle.main.bundleIdentifier
      else { return }
      let folder = library.appendingPathComponent("SplashBoard/Snapshots/\(bundle) - {DEFAULT GROUP}")
      guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
      else { return }
      let fill = colour(ground)
      for file in files {
        // Only the pictures iOS can read, each kept at its own size.
        guard let data = try? Data(contentsOf: file), let picture = UIImage(data: data)?.cgImage else { continue }
        let size = CGSize(width: picture.width, height: picture.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let painted = UIGraphicsImageRenderer(size: size, format: format).pngData { context in
          fill.setFill()
          context.fill(CGRect(origin: .zero, size: size))
        }
        try? painted.write(to: file, options: .atomic)
      }
    }
  }
}

/// The app's screen (Main.storyboard). Until Flutter draws its first frame it shows the launch screen once more, which
/// is dark for every icon; that left a dark flash between the launch picture and the opening for a non-dark icon (the
/// owner, 2026-11-15). It shows the ground of the icon last named instead.
class BazaarViewController: FlutterViewController {
  override func awakeFromNib() {
    super.awakeFromNib()
    guard let ground = LaunchPicture.kept else { return }
    let splash = UIView()
    splash.backgroundColor = ground
    splashScreenView = splash
  }
}

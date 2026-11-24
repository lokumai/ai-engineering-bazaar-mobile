import AVFoundation
import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Each app icon's name on the Dart side (lib/shared/app_icon/) and its alternate icon in the asset catalog; the
  /// default, fezCream, is the primary icon (nil).
  static let appIcons: [String: String?] = [
    "fezCream": nil,
    "fezDark": "AppIconFezDark",
    "antennaCream": "AppIconAntennaCream",
    "antennaDark": "AppIconAntennaDark",
    "beanieCream": "AppIconBeanieCream",
    "beanieDark": "AppIconBeanieDark",
    "domeCream": "AppIconDomeCream",
    "domeDark": "AppIconDomeDark",
    "mortarboardCream": "AppIconMortarboardCream",
    "mortarboardDark": "AppIconMortarboardDark",
    "tvCream": "AppIconTvCream",
    "tvDark": "AppIconTvDark",
    "turbanCream": "AppIconTurbanCream",
    "turbanDark": "AppIconTurbanDark",
    "earsCream": "AppIconEarsCream",
    "earsDark": "AppIconEarsDark",
    "wizardCream": "AppIconWizardCream",
    "wizardDark": "AppIconWizardDark",
    "topHatCream": "AppIconTopHatCream",
    "topHatDark": "AppIconTopHatDark",
    "visorCream": "AppIconVisorCream",
    "visorDark": "AppIconVisorDark",
    "crownCream": "AppIconCrownCream",
    "crownDark": "AppIconCrownDark",
  ]

  /// The ground of each look the Dart side names (lib/infrastructure/theme/launch_ground_channel.dart): the page colour
  /// of the light look and of the dark one, as lib/shared/design_system paints them. The app opens on it.
  static let launchGrounds: [String: UInt32] = [
    "light": 0xfdfbf7,
    "dark": 0x1d1f27,
  ]

  /// The phone's voice, which reads a module aloud (plan 15.1).
  private var speech: Speech?

  /// The links the phone hands the app (plan 17.2).
  private var links: Links?

  /// The phone's QR code scanner (plan 17.5).
  private var codeScanner: CodeScanner?

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
        guard let icon = call.arguments as? String, let name = AppDelegate.appIcons[icon] else {
          return result(FlutterError(code: "unknown-icon", message: call.arguments as? String, details: nil))
        }
        let app = UIApplication.shared
        // The system tells the reader of every change, so an icon already in place is left alone (each launch names
        // the chosen icon again).
        guard app.supportsAlternateIcons, app.alternateIconName != name else { return result(nil) }
        app.setAlternateIconName(name) { error in
          if let error {
            NSLog("Bazaar: app icon %@ not set: %@", name ?? "default", error.localizedDescription)
          }
          // UIKit does not say on which queue it calls back; a channel is answered on the main one.
          DispatchQueue.main.async {
            result(error.map { FlutterError(code: "not-changed", message: $0.localizedDescription, details: nil) })
          }
        }
      }
    // lib/infrastructure/theme/launch_ground_channel.dart names the reader's look on every launch and every choice; the
    // next launch opens on its page colour.
    FlutterMethodChannel(name: "dev.lokumai.bazaar/launch_ground", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "keep" else { return result(FlutterMethodNotImplemented) }
        guard let look = call.arguments as? String, let ground = AppDelegate.launchGrounds[look] else {
          return result(FlutterError(code: "unknown-look", message: call.arguments as? String, details: nil))
        }
        LaunchPicture.keep(ground)
        result(nil)
      }
    // lib/infrastructure/speech/phone_speech.dart reads a module aloud with the phone's own voice.
    speech = Speech(messenger: registrar.messenger())
    // lib/infrastructure/links/link_channel.dart opens the site's links in the app; the scene hands them over, the one
    // the app was opened with included.
    let links = Links(messenger: registrar.messenger())
    registrar.addSceneDelegate(links)
    self.links = links
    // lib/infrastructure/share/share_channel.dart shares a module's address and a progress link.
    FlutterMethodChannel(name: "dev.lokumai.bazaar/share", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "share" else { return result(FlutterMethodNotImplemented) }
        guard let text = call.arguments as? String, !text.isEmpty, let presenter = ShareSheet.presenter() else {
          return result(FlutterError(code: "no-sheet", message: nil, details: nil))
        }
        ShareSheet.show(text, from: presenter)
        result(nil)
      }
    // lib/infrastructure/scanner/code_scanner_channel.dart reads the website's code in the app.
    codeScanner = CodeScanner(messenger: registrar.messenger())
  }
}

/// The links the phone hands the app (plan 17.2), on the channel lib/infrastructure/links/link_channel.dart listens to:
/// the site's pages its apple-app-site-association names (universal links, once the Associated Domains entitlement is
/// on: Runner.entitlements) and the app's own scheme `aibazaar://transfer` (Info.plist), which the site's transfer page
/// offers. Flutter's own deep linking stays off (Info.plist), so no link reaches the router.
///
/// A link that comes before the Dart side asks waits; `ready` gives the ones waiting and from then on each comes as
/// `link`.
final class Links: NSObject, FlutterSceneLifeCycleDelegate {
  private let channel: FlutterMethodChannel
  private var waiting: [String] = []
  private var ready = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dev.lokumai.bazaar/links", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, call.method == "ready" else { return result(FlutterMethodNotImplemented) }
      self.ready = true
      result(self.waiting)
      self.waiting.removeAll()
    }
  }

  private func receive(_ url: URL?) {
    guard let link = url?.absoluteString else { return }
    if ready {
      channel.invokeMethod("link", arguments: link)
    } else {
      waiting.append(link)
    }
  }

  private func receive(_ activity: NSUserActivity) -> Bool {
    guard activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL else { return false }
    receive(url)
    return true
  }

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let options = connectionOptions else { return false }
    var handled = false
    for context in options.urlContexts {
      receive(context.url)
      handled = true
    }
    for activity in options.userActivities where receive(activity) {
      handled = true
    }
    return handled
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    for context in URLContexts {
      receive(context.url)
    }
    return !URLContexts.isEmpty
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
    receive(userActivity)
  }
}

/// The phone's share sheet (plan 17.3): the text is offered to the phone's apps; nothing is sent until the reader picks
/// one.
enum ShareSheet {
  /// The screen on top, which presents the sheet.
  static func presenter() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let shown = top?.presentedViewController {
      top = shown
    }
    return top
  }

  static func show(_ text: String, from presenter: UIViewController) {
    let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    // On an iPad the sheet is a popover, which needs a place: the middle of the screen, with no arrow.
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    presenter.present(sheet, animated: true)
  }
}

/// The phone's QR code scanner (plan 17.5), on the channel lib/infrastructure/scanner/code_scanner_channel.dart calls:
/// `available`, and `scan` with the screen's title, which answers the code's text, or nil when the reader went back
/// (Cancel). The camera screen is the app's own (AVFoundation, QR codes only); iOS asks the reader once for the camera
/// (Info.plist NSCameraUsageDescription), and a camera not allowed answers `denied`. No picture is kept; nothing leaves
/// the phone.
final class CodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
  private let channel: FlutterMethodChannel
  private var pending: FlutterResult?
  /// Whether the camera question is up: a second scan then is `busy` too, as `pending` is set only once it is answered.
  private var asking = false
  private var session: AVCaptureSession?
  private weak var screen: UIViewController?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dev.lokumai.bazaar/scanner", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "available":
        result(AVCaptureDevice.default(for: .video) != nil)
      case "scan":
        // The title and Cancel in the app's language, which may not be the phone's (review 8).
        let texts = call.arguments as? [String: Any] ?? [:]
        self.start(
          title: texts["title"] as? String ?? "", cancel: texts["cancel"] as? String ?? "", result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func start(title: String, cancel: String, result: @escaping FlutterResult) {
    // A scan whose screen is not up, or is gone (the screen is held weakly), was dropped by UIKit unseen: it is answered
    // now rather than leaving every later scan busy until the app restarts (review 9, finding 11).
    if pending != nil, screen?.presentingViewController == nil { dropped() }
    guard pending == nil, !asking else { return result(FlutterError(code: "busy", message: nil, details: nil)) }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      open(title: title, cancel: cancel, result: result)
    case .notDetermined:
      asking = true
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          self.asking = false
          if granted {
            self.open(title: title, cancel: cancel, result: result)
          } else {
            result(FlutterError(code: "denied", message: nil, details: nil))
          }
        }
      }
    default:
      result(FlutterError(code: "denied", message: nil, details: nil))
    }
  }

  private func open(title: String, cancel: String, result: @escaping FlutterResult) {
    let session = AVCaptureSession()
    let output = AVCaptureMetadataOutput()
    guard let device = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input), session.canAddOutput(output),
      let presenter = ShareSheet.presenter()
    else {
      return result(FlutterError(code: "no-camera", message: nil, details: nil))
    }
    session.addInput(input)
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: .main)
    output.metadataObjectTypes = [.qr]
    let navigation = UINavigationController(
      rootViewController: ScannerScreen(session: session, title: title, cancel: cancel) { [weak self] in self?.finish(nil) })
    navigation.modalPresentationStyle = .fullScreen
    navigation.overrideUserInterfaceStyle = .dark
    pending = result
    self.session = session
    screen = navigation
    presenter.present(navigation, animated: true)
    // UIKit drops a presentation over a screen that is being dismissed, with only a console warning; a presentation it
    // takes has its presenter at once (review 9, finding 11).
    guard navigation.presentingViewController != nil else { return dropped() }
    DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
  }

  /// Answers `no-camera` for a scan whose screen UIKit did not show, and lets the camera go.
  private func dropped() {
    guard let result = pending else { return }
    pending = nil
    let session = self.session
    self.session = nil
    DispatchQueue.global(qos: .userInitiated).async { session?.stopRunning() }
    screen = nil
    result(FlutterError(code: "no-camera", message: nil, details: nil))
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection
  ) {
    let code = metadataObjects.compactMap { ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }.first
    guard let code else { return }
    finish(code)
  }

  private func finish(_ text: String?) {
    guard let result = pending else { return }
    pending = nil
    let session = self.session
    self.session = nil
    DispatchQueue.global(qos: .userInitiated).async { session?.stopRunning() }
    screen?.dismiss(animated: true)
    screen = nil
    result(text)
  }
}

/// The camera screen of [CodeScanner]: the camera's picture across the screen, a square to aim with, the title and
/// Cancel above.
final class ScannerScreen: UIViewController {
  private let session: AVCaptureSession
  private let onCancel: () -> Void
  private var preview: AVCaptureVideoPreviewLayer?
  private let aim = CAShapeLayer()

  init(session: AVCaptureSession, title: String, cancel: String, onCancel: @escaping () -> Void) {
    self.session = session
    self.onCancel = onCancel
    super.init(nibName: nil, bundle: nil)
    navigationItem.title = title
    // The app's own word, as the title is: the system Cancel would follow the phone's language (review 8).
    navigationItem.leftBarButtonItem =
      cancel.isEmpty
      ? UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
      : UIBarButtonItem(title: cancel, style: .plain, target: self, action: #selector(cancelTapped))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    view.layer.addSublayer(preview)
    self.preview = preview
    aim.strokeColor = UIColor.white.cgColor
    aim.fillColor = UIColor.clear.cgColor
    aim.lineWidth = 3
    view.layer.addSublayer(aim)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    preview?.frame = view.bounds
    turnPicture()
    let side = min(view.bounds.width, view.bounds.height) * 0.65
    let square = CGRect(x: view.bounds.midX - side / 2, y: view.bounds.midY - side / 2, width: side, height: side)
    aim.path = UIBezierPath(roundedRect: square, cornerRadius: 16).cgPath
  }

  @objc private func cancelTapped() {
    onCancel()
  }

  /// Turns the camera's picture with the screen, so it stands upright on an iPad held sideways or an iPhone turned
  /// (plan 20.9); the camera gives it upright for a phone held straight only.
  private func turnPicture() {
    guard let connection = preview?.connection,
      let orientation = view.window?.windowScene?.interfaceOrientation
    else { return }
    if #available(iOS 17.0, *) {
      let angle: CGFloat =
        switch orientation {
        case .landscapeRight: 0
        case .landscapeLeft: 180
        case .portraitUpsideDown: 270
        default: 90
        }
      if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
    } else if connection.isVideoOrientationSupported {
      connection.videoOrientation =
        switch orientation {
        case .landscapeRight: .landscapeRight
        case .landscapeLeft: .landscapeLeft
        case .portraitUpsideDown: .portraitUpsideDown
        default: .portrait
        }
    }
  }
}

/// The phone's own voice (AVSpeechSynthesizer), which reads a module aloud (plan 15.1), on the channel
/// lib/infrastructure/speech/phone_speech.dart calls: `canSpeak` with a language, `speak` with an id, the words, the tag
/// and the rate, and `stop`. Each speak's id goes back in `done` once its words are said or cut. Nothing leaves the
/// phone.
///
/// A call or another app's sound that takes the phone's audio cuts the reading, and `interrupted` with its id tells the
/// Dart side, which pauses where it was (plan 19.8). The Dart side names the reading in `show` (its title and whether it
/// plays, or null once it ends), which the lock screen, the Control Center and the headphones show and answer: Play and
/// Pause come back as `control` `play` or `pause`.
final class Speech: NSObject, AVSpeechSynthesizerDelegate {
  static let channel = "dev.lokumai.bazaar/speech"

  private let channel: FlutterMethodChannel
  private let synthesizer = AVSpeechSynthesizer()

  /// The speak each utterance belongs to, its place in it and whether it is the last.
  private var parts: [ObjectIdentifier: (id: Int, index: Int, last: Bool)] = [:]

  /// The speaks whose end has been told, so a cut queue tells it once.
  private var ended: Set<Int> = []

  /// The lock screen's and the headphones' commands, answered while a reading is shown.
  private var commands: [Any] = []

  /// Whether another app's sound paused the reading, which then reads on when that sound ends and iOS says it may.
  private var pausedBySound = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Speech.channel, binaryMessenger: messenger)
    super.init()
    synthesizer.delegate = self
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    NotificationCenter.default.addObserver(
      self, selector: #selector(interrupted(_:)), name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance())
    NotificationCenter.default.addObserver(
      self, selector: #selector(routeChanged(_:)), name: AVAudioSession.routeChangeNotification,
      object: AVAudioSession.sharedInstance())
  }

  /// A call, an alarm or another app took the sound: the reading stops, and the Dart side pauses where it was. When a
  /// short sound such as Siri or a Maps prompt ends and iOS says the app may play again, the reading goes on, as it
  /// does on Android (review 4).
  @objc private func interrupted(_ notification: Notification) {
    guard let info = notification.userInfo, let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: raw)
    else { return }
    switch type {
    case .began:
      pausedBySound = !parts.isEmpty
      pauseReading()
    case .ended:
      let options = AVAudioSession.InterruptionOptions(
        rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
      DispatchQueue.main.async { [weak self] in
        guard let self, self.pausedBySound else { return }
        self.pausedBySound = false
        if options.contains(.shouldResume) { self.channel.invokeMethod("control", arguments: "play") }
      }
    @unknown default:
      return
    }
  }

  /// The headphones were taken off or lost, as Bluetooth ones whose battery ran out: the reading pauses rather than go
  /// on aloud through the speaker (plan 20.3).
  @objc private func routeChanged(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
      AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable
    else { return }
    DispatchQueue.main.async { [weak self] in self?.pauseReading() }
  }

  /// Stops the words being said and tells the Dart side, which pauses where it was.
  private func pauseReading() {
    guard let id = parts.values.first?.id else { return }
    channel.invokeMethod("interrupted", arguments: id)
    synthesizer.stopSpeaking(at: .immediate)
    endAll()
  }

  /// Names the reading to the lock screen and the headphones, [title] and whether it is [playing], or nothing.
  private func show(title: String?, playing: Bool) {
    let center = MPRemoteCommandCenter.shared()
    guard let title else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      for command in [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand] {
        command.removeTarget(nil)
        command.isEnabled = false
      }
      commands.removeAll()
      return
    }
    if commands.isEmpty {
      commands = [
        center.playCommand.addTarget { [weak self] _ in self?.control("play") ?? .commandFailed },
        center.pauseCommand.addTarget { [weak self] _ in self?.control("pause") ?? .commandFailed },
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
          let playing = (MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate]
            as? Double ?? 0) > 0
          return self?.control(playing ? "pause" : "play") ?? .commandFailed
        },
      ]
      for command in [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand] {
        command.isEnabled = true
      }
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
    ]
  }

  private func control(_ command: String) -> MPRemoteCommandHandlerStatus {
    channel.invokeMethod("control", arguments: command)
    return .success
  }

  /// Whether a voice of the phone speaks [language], a language code such as `tr`.
  static func hasVoice(for language: String, among voices: [String]) -> Bool {
    voices.contains { voice in
      let code = voice.lowercased()
      return code == language || code.hasPrefix(language + "-") || code.hasPrefix(language + "_")
    }
  }

  /// The best voice the phone has for [tag], such as `tr-TR` (the owner, 2026-11-18): a premium or enhanced one the
  /// reader downloaded in Settings, Accessibility, Spoken Content, Voices, before the compact one iOS ships; of the
  /// tag's own country first, then of its language; never a novelty voice.
  static func bestVoice(for tag: String) -> AVSpeechSynthesisVoice? {
    let wanted = tag.lowercased().replacingOccurrences(of: "_", with: "-")
    let language = wanted.split(separator: "-").first.map(String.init) ?? wanted
    let voices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
      if #available(iOS 17.0, *), voice.voiceTraits.contains(.isNoveltyVoice) { return false }
      let code = voice.language.lowercased().replacingOccurrences(of: "_", with: "-")
      return code == wanted || code.hasPrefix(language + "-") || code == language
    }
    func rank(_ voice: AVSpeechSynthesisVoice) -> (Int, Int) {
      let country = voice.language.lowercased().replacingOccurrences(of: "_", with: "-") == wanted ? 1 : 0
      return (country, voice.quality.rawValue)
    }
    return voices.max { rank($0) < rank($1) } ?? AVSpeechSynthesisVoice(language: tag)
  }

  private func handle(_ call: FlutterMethodCall, _ result: FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "canSpeak":
      guard let language = arguments["language"] as? String else { return result(false) }
      result(Speech.hasVoice(for: language, among: AVSpeechSynthesisVoice.speechVoices().map(\.language)))
    case "speak":
      // The reader read on, or began another reading, before the other sound ended.
      pausedBySound = false
      guard let id = arguments["id"] as? Int, let texts = arguments["texts"] as? [String], !texts.isEmpty,
        let tag = arguments["tag"] as? String, let voice = Speech.bestVoice(for: tag)
      else { return result(false) }
      // Heard with the ring switch on silent and with the screen off, as a reader who taps Listen means to hear it;
      // Info.plist's audio background mode keeps it going once the app leaves the screen. The sound is the app's alone,
      // as a podcast's: other sound pauses rather than lowers, since iOS shows an app that mixes with others (as
      // `.duckOthers` does) nowhere on the lock screen, the status bar or the headphones (plan 19.8).
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playback, mode: .spokenAudio, options: [])
      let active = (try? session.setActive(true)) != nil
      // The words being said, and those waiting, are cut; their speak comes back as done.
      if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
      endAll()
      guard active else {
        // A call holds the sound: nothing is said, and the player waits on its part, as if the call had come during
        // the reading, as on Android (plan 20.8).
        channel.invokeMethod("interrupted", arguments: id)
        end(id)
        return result(true)
      }
      let rate = Float(arguments["rate"] as? Double ?? Double(AVSpeechUtteranceDefaultSpeechRate))
      // Every part queued at once: the phone reads on from one to the next without the app.
      for (index, text) in texts.enumerated() {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        utterance.postUtteranceDelay = 0.15
        parts[ObjectIdentifier(utterance)] = (id, index, index == texts.count - 1)
        synthesizer.speak(utterance)
      }
      result(true)
    case "stop":
      // Not the end of a pause by another app's sound: the Dart side stops the words when it pauses for it, and a
      // later play only reads on a reading still paused.
      synthesizer.stopSpeaking(at: .immediate)
      endAll()
      result(nil)
    case "show":
      let reading = call.arguments as? [String: Any]
      show(title: reading?["title"] as? String, playing: reading?["playing"] as? Bool ?? false)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Tells the end of every speak still queued, once each.
  private func endAll() {
    let ids = Set(parts.values.map(\.id))
    parts.removeAll()
    for id in ids { end(id) }
  }

  private func end(_ id: Int) {
    guard ended.insert(id).inserted else { return }
    channel.invokeMethod("done", arguments: id)
    // Other sound comes back up once nothing is said: a moment later, as a new speak follows at once.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
      guard let self, self.parts.isEmpty, !self.synthesizer.isSpeaking else { return }
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    guard let part = parts[ObjectIdentifier(utterance)] else { return }
    channel.invokeMethod("part", arguments: ["id": part.id, "index": part.index])
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    guard let part = parts.removeValue(forKey: ObjectIdentifier(utterance)) else { return }
    if part.last { end(part.id) }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    guard let part = parts.removeValue(forKey: ObjectIdentifier(utterance)) else { return }
    let id = part.id
    parts = parts.filter { $0.value.id != id }
    end(id)
  }
}

/// iOS opens an app on a picture of its launch screen that it keeps in the app's Library/SplashBoard, and the launch
/// screen is one, on the cream ground of the light look the app opens in until the reader chooses (the owner,
/// 2026-11-16). Repainting those pictures in the ground
/// of the reader's look lets the app open on it from the next launch (the owner, 2026-11-14, 2026-11-15: the look, not
/// the icon). The folder is not documented: when it is missing or a picture cannot be read, nothing changes and the app
/// opens on the cream ground. iOS draws the pictures
/// again after an update, and the next launch paints them again.
enum LaunchPicture {
  /// Where the ground of the look last named is kept, for [BazaarViewController] on the next launch.
  static let groundKey = "BazaarLaunchGround"

  /// The ground of the look last named, as a colour; nil before the Dart side first named one.
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
/// is cream for every look; that left a flash between the launch picture and the opening for the other look (the owner,
/// 2026-11-15). It shows the ground of the look last named instead.
class BazaarViewController: FlutterViewController {
  override func awakeFromNib() {
    super.awakeFromNib()
    guard let ground = LaunchPicture.kept else { return }
    let splash = UIView()
    splash.backgroundColor = ground
    splashScreenView = splash
  }
}

/// The links the phone hands the app (plan 17.2): the site's pages and progress transfers.
///
/// The phone may hand one before anything listens (the link the app was opened with): those wait in [takeWaiting];
/// the ones that come while the app runs arrive on [links].
abstract interface class ILinkSource {
  /// The links that came while the app was not listening, once; later calls give the ones since.
  Future<List<Uri>> takeWaiting();

  /// The links handed to the app while it runs.
  Stream<Uri> get links;
}

/// The phone's share sheet (plan 17.3), which offers its apps (mail, messages) to send a text.
abstract interface class IShareSheet {
  /// Offers [text] to the phone's apps; true once the sheet was shown, false when it could not be.
  Future<bool> share(String text);
}

/// No links: a phone without the channel, and the tests.
final class NoLinkSource implements ILinkSource {
  const NoLinkSource();

  @override
  Future<List<Uri>> takeWaiting() async => const [];

  @override
  Stream<Uri> get links => const Stream.empty();
}

/// No share sheet: a phone without the channel, and the tests.
final class NoShareSheet implements IShareSheet {
  const NoShareSheet();

  @override
  Future<bool> share(String text) async => false;
}

/// The phone's camera reading a QR code in the app (plan 17.5): the code the website's Progress page shows (Move to
/// the app), read without leaving the app. On Android it is Google's code scanner, which needs no camera permission;
/// on iOS the app's own camera screen, which asks for it once. Nothing is recorded and nothing leaves the phone.
abstract interface class ICodeScanner {
  /// Whether this phone can read a code in the app (Android without Google Play services cannot).
  Future<bool> available();

  /// Opens the camera, [title] over it, until a code is read or the reader goes back.
  Future<ScanOutcome> scan(String title);
}

/// What a scan ended with.
sealed class ScanOutcome {
  const ScanOutcome();
}

/// A code was read: its [text].
final class ScanRead extends ScanOutcome {
  const ScanRead(this.text);

  final String text;
}

/// The reader went back without reading a code.
final class ScanCancelled extends ScanOutcome {
  const ScanCancelled();
}

/// The camera is not allowed for the app.
final class ScanDenied extends ScanOutcome {
  const ScanDenied();
}

/// The camera or the scanner could not be opened.
final class ScanFailed extends ScanOutcome {
  const ScanFailed();
}

/// No scanner: a phone without the channel, and the tests.
final class NoCodeScanner implements ICodeScanner {
  const NoCodeScanner();

  @override
  Future<bool> available() async => false;

  @override
  Future<ScanOutcome> scan(String title) async => const ScanFailed();
}

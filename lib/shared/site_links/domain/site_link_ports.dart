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

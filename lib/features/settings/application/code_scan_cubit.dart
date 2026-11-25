import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Scan the code (plan 17.5): the camera reads the code the website's Progress page shows (Move to the app), and a
/// progress link found in it opens the transfer page, as the same link opened from the phone's camera would. Any other
/// code is said to be one; the camera off or missing is said too.
///
/// A Cubit: one call per press, with nothing for an event stream to add; a press is ignored while a scan runs.
final class CodeScanCubit extends Cubit<CodeScanState> {
  CodeScanCubit({required this._scanner, required this._site}) : super(const CodeScanState());

  final ICodeScanner _scanner;
  final Uri _site;

  /// Asks once whether this phone can scan in the app; the button shows only then.
  Future<void> load() async {
    final available = await _scanner.available();
    if (!isClosed) emit(CodeScanState(available: available));
  }

  /// Opens the camera with [title] over it and [cancel] on its way back.
  Future<void> scan(String title, {required String cancel}) async {
    if (!state.available || state.scan is CodeScanScanning) return;
    emit(state.at(const CodeScanScanning()));
    CodeScan next;
    try {
      next = switch (await _scanner.scan(title, cancel: cancel)) {
        ScanRead(:final text) => switch (_linkIn(text)) {
          SiteTransfer(:final payload) => CodeScanFound(payload),
          _ => const CodeScanNotALink(),
        },
        ScanCancelled() => const CodeScanIdle(),
        ScanDenied() => const CodeScanDenied(),
        ScanFailed() => const CodeScanFailed(),
      };
    } on Object {
      // Whatever went wrong, the scan ends, or the button stays dead until Settings is opened again (review 5,
      // finding 1).
      next = const CodeScanFailed();
    }
    if (!isClosed) emit(state.at(next));
  }

  /// The transfer page was opened with what was found.
  void opened() {
    if (state.scan is CodeScanFound) emit(state.at(const CodeScanIdle()));
  }

  /// The link in a code. The site builds its code from the address it is opened at, so a code from a copy of the site
  /// (a test server on the computer, http and a port) carries another address: a transfer page is read at any address,
  /// since its progress is in the link and nothing is added before the reader's press. Other pages keep the site's
  /// own address.
  SiteLink? _linkIn(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return null;
    final link = SiteLink.parse(uri, _site);
    if (link != null || !uri.isScheme('http') && !uri.isScheme('https')) return link;
    final onSite = SiteLink.parse(
      Uri(scheme: 'https', host: _site.host, path: uri.path, fragment: uri.fragment),
      _site,
    );
    return onSite is SiteTransfer ? onSite : null;
  }
}

/// Where a scan is: a sealed family, so a payload exists only once a transfer was found (review 11, architecture 9).
sealed class CodeScan extends Equatable {
  const CodeScan();

  @override
  List<Object?> get props => [];
}

final class CodeScanIdle extends CodeScan {
  const CodeScanIdle();
}

final class CodeScanScanning extends CodeScan {
  const CodeScanScanning();
}

/// A progress link was read; [payload] opens the transfer page.
final class CodeScanFound extends CodeScan {
  const CodeScanFound(this.payload);

  final String payload;

  @override
  List<Object?> get props => [payload];
}

final class CodeScanNotALink extends CodeScan {
  const CodeScanNotALink();
}

final class CodeScanDenied extends CodeScan {
  const CodeScanDenied();
}

final class CodeScanFailed extends CodeScan {
  const CodeScanFailed();
}

/// Whether the phone can scan, and where the [scan] is. One state with two fields, by the rule's third exception (form
/// persistence): [available] is asked once and persists through every step of a scan, which is itself sealed.
final class CodeScanState extends Equatable {
  const CodeScanState({this.available = false, this.scan = const CodeScanIdle()});

  /// Whether this phone can scan in the app; false until asked.
  final bool available;
  final CodeScan scan;

  CodeScanState at(CodeScan scan) => CodeScanState(available: available, scan: scan);

  @override
  List<Object?> get props => [available, scan];
}

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

  /// Opens the camera with [title] over it.
  Future<void> scan(String title) async {
    if (!state.available || state.status == CodeScanStatus.scanning) return;
    emit(state.copyWith(status: CodeScanStatus.scanning));
    CodeScanState next;
    try {
      next = switch (await _scanner.scan(title)) {
        ScanRead(:final text) => switch (_linkIn(text)) {
          SiteTransfer(:final payload) => state.copyWith(status: CodeScanStatus.found, payload: payload),
          _ => state.copyWith(status: CodeScanStatus.notALink),
        },
        ScanCancelled() => state.copyWith(status: CodeScanStatus.idle),
        ScanDenied() => state.copyWith(status: CodeScanStatus.denied),
        ScanFailed() => state.copyWith(status: CodeScanStatus.failed),
      };
    } on Object {
      // Whatever went wrong, the scan ends, or the button stays dead until Settings is opened again (review 5,
      // finding 1).
      next = state.copyWith(status: CodeScanStatus.failed);
    }
    if (!isClosed) emit(next);
  }

  /// The transfer page was opened with what was found.
  void opened() {
    if (state.status == CodeScanStatus.found) emit(state.copyWith(status: CodeScanStatus.idle));
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

/// Where a scan is.
enum CodeScanStatus { idle, scanning, found, notALink, denied, failed }

final class CodeScanState extends Equatable {
  const CodeScanState({this.available = false, this.status = CodeScanStatus.idle, this.payload});

  /// Whether this phone can scan in the app; false until asked.
  final bool available;
  final CodeScanStatus status;

  /// The transfer's payload once one was [CodeScanStatus.found].
  final String? payload;

  CodeScanState copyWith({required CodeScanStatus status, String? payload}) =>
      CodeScanState(available: available, status: status, payload: payload);

  @override
  List<Object?> get props => [available, status, payload];
}

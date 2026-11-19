import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Send to the website (plan 17.1): the record's progress as a transfer link, offered through the phone's share sheet,
/// which the reader opens on the computer. The link carries the progress in its fragment, which no browser sends to a
/// server; nothing leaves the phone until the reader picks an app in the sheet.
///
/// A Cubit: one atomic call per press, with nothing for an event stream to add; the press is ignored while one runs.
final class WebsiteLinkCubit extends Cubit<WebsiteLinkState> {
  WebsiteLinkCubit({required this._recordBloc, required this._packer, required this._shareSheet, required this._site})
    : super(WebsiteLinkState.idle);

  final RecordBloc _recordBloc;
  final ITransferPacker _packer;
  final IShareSheet _shareSheet;
  final Uri _site;

  Future<void> send() async {
    if (state == WebsiteLinkState.sending) return;
    final record = switch (_recordBloc.state) {
      RecordReady(:final record) => record,
      RecordLoading() => null,
    };
    if (record == null) return;
    final text = encodeTransfer(record);
    if (decodeTransfer(text)?.isEmpty ?? true) {
      emit(WebsiteLinkState.empty);
      return;
    }
    emit(WebsiteLinkState.sending);
    final shown = await _shareSheet.share(transferLink(_site, _packer.pack(text)).toString());
    emit(shown ? WebsiteLinkState.idle : WebsiteLinkState.failed);
  }
}

/// Where Send to the website is.
enum WebsiteLinkState {
  /// Nothing to say: not pressed yet, or the sheet was shown.
  idle,

  /// The sheet is being asked for.
  sending,

  /// The record carries no progress to send.
  empty,

  /// The sheet could not be shown.
  failed,
}

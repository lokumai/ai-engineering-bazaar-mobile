@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/website_line.dart';
import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/reducers.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/accessibility.dart';
import '../../../../support/content_fixture.dart';
import '../data_host.dart';

/// A share sheet that keeps what it was given, shown unless [shows] is false.
final class _Sheet implements IShareSheet {
  _Sheet({this.shows = true});

  final bool shows;
  final shared = <String>[];

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return shows;
  }
}

final _completed = signOff(RecordData.empty, 'alpha/first', 'a1b2c3d', '2026-11-02T09:15:30.123Z');

void main() {
  testWidgets('Send to the website shares a transfer link to the site that carries the progress (plan 17.1)', (
    tester,
  ) async {
    final (data, _) = dataBlocAt();
    final sheet = _Sheet();
    await pumpDataHost(
      tester,
      const WebsiteLine(),
      data: data,
      record: recordBlocAt(record: _completed),
      shareSheet: sheet,
    );

    await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
    await tester.pump();

    final link = Uri.parse(sheet.shared.single);
    expect(link.toString(), startsWith('${testContentBaseUrl}transfer/#t='));
    final payload = (SiteLink.parse(link, Uri.parse(testContentBaseUrl))! as SiteTransfer).payload;
    final progress = decodeTransfer(const DeflateTransferPacker().unpack(payload)!)!;
    expect(progress.engineers['alpha/first']!.signedOff, '2026-11-02T09:15:30.123Z');
    expect(progress.completed(Track.engineers), 1);
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);
  });

  testWidgets('with nothing to send it says so and opens no sheet', (tester) async {
    final (data, _) = dataBlocAt();
    final sheet = _Sheet();
    await pumpDataHost(tester, const WebsiteLine(), data: data, shareSheet: sheet);

    await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
    await tester.pump();

    expect(sheet.shared, isEmpty);
    expect(find.text('Nothing to send yet: no module is completed or ticked.'), findsOneWidget);
  });

  testWidgets('a sheet that cannot be shown is said', (tester) async {
    final (data, _) = dataBlocAt();
    await pumpDataHost(
      tester,
      const WebsiteLine(),
      data: data,
      record: recordBlocAt(record: _completed),
      shareSheet: _Sheet(shows: false),
    );

    await tester.tap(find.byKey(const ValueKey('settings-send-to-website')));
    await tester.pump();

    expect(find.text('The share menu did not open.'), findsOneWidget);
  });
}

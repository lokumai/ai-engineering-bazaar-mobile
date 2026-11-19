import 'package:ai_engineering_bazaar/shared/design_system/share_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("each phone's own share mark (plan 18.14)", (tester) async {
    for (final (platform, icon) in [
      (TargetPlatform.iOS, Icons.ios_share_outlined),
      (TargetPlatform.android, Icons.share_outlined),
    ]) {
      late IconData shown;
      await tester.pumpWidget(
        Theme(
          data: ThemeData(platform: platform),
          child: Builder(
            builder: (context) {
              shown = shareIcon(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(shown, icon, reason: '$platform');
    }
  });
}

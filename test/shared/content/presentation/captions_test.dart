import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/captions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;
  setUpAll(() async => s = await S.load(const Locale('en')));

  // A14: the web's em dash becomes ' · '.
  test('captions read FIG. and TBL. with the title after a middle dot', () {
    expect(figureCaption(s, number: '13.2', title: 'Title'), 'FIG. 13.2 · Title');
    expect(figureCaption(s, number: '13.2'), 'FIG. 13.2');
    expect(tableCaption(s, number: '4', title: 'Results'), 'TBL. 4 · Results');
  });

  test('an empty title gives the label alone', () {
    expect(figureCaption(s, number: '1', title: ''), 'FIG. 1');
    expect(tableCaption(s, number: '4'), 'TBL. 4');
  });
}

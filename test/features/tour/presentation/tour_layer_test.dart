@Tags(['widget'])
library;

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:ai_engineering_bazaar/features/tour/presentation/tour_layer.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/accessibility.dart';
import '../../../support/bazaar_app_harness.dart';

/// The Apprentice's tour (plan 11.3).

final _asking = find.byKey(const ValueKey('tour-asking'));
final _scrim = find.byKey(const ValueKey('tour-scrim'));
final _next = find.byKey(const ValueKey('tour-next'));
final _skip = find.byKey(const ValueKey('tour-skip'));
final _robot = find.byKey(const ValueKey('tour-robot'));

Future<(GoRouter, MemoryTourStore)> _pump(
  WidgetTester tester, {
  TourRecord record = const TourRecord(),
  String at = '/',
  Locale locale = const Locale('en'),
  bool reduced = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = MemoryTourStore(record);
  final tour = TourCubit(store: store);
  await tour.load();
  final router = AppRouterFactory(initialLocation: at).create();
  addTearDown(router.dispose);
  final app = bazaarTestApp(router: router, tour: tour, locale: locale);
  await tester.pumpWidget(reduced ? _Reduced(child: app) : app);
  await _walk(tester);
  return (router, store);
}

/// Lets the page settle and the Apprentice walk to its place.
Future<void> _walk(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _walk(tester);
}

/// The bubble's words.
Finder _says(String text) => find.text(text);

/// The rect the scrim leaves clear.
Rect? _hole(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(_scrim);
  return (paint.painter! as dynamic).hole as Rect?;
}

Rect _spot(WidgetTester tester, String spot) {
  final box = TourTarget.contextOf(spot)!.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

const _hello =
    "Hi, I'm the Apprentice. This is a learning app: we teach AI engineering level by level, module by module. Shall "
    'I show you around?';

void main() {
  testWidgets('a reader never offered the tour sees none, on any page', (tester) async {
    await _pump(tester);
    expect(_asking, findsNothing);
    expect(_scrim, findsNothing);

    await _tap(tester, find.text('Catalog').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('offered, the Apprentice asks on Home; Later, and no page is ever shown', (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(asking: true));

    expect(_asking, findsOneWidget);
    expect(_says(_hello), findsOneWidget);
    expect(_robot, findsOneWidget);
    await expectPlatformGuidelines(tester, platform: TargetPlatform.android);

    await _tap(tester, find.byKey(const ValueKey('tour-later')));
    expect(_asking, findsNothing);
    expect(_scrim, findsNothing);
    expect(store.kept, const TourRecord());

    await _tap(tester, find.text('Quiz').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('the question is in Turkish too', (tester) async {
    await _pump(tester, record: const TourRecord(asking: true), locale: const Locale('tr'));

    expect(_says('Gezdir'), findsOneWidget);
    expect(_says('Sonra'), findsOneWidget);
    expect(find.textContaining('Merhaba, ben Çırak.'), findsOneWidget);
  });

  testWidgets('said yes, it shows Home a place at a time, walking to each, and Home is done', (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(asking: true));

    await _tap(tester, find.byKey(const ValueKey('tour-accept')));
    expect(_asking, findsNothing);

    final steps = [
      (TourSpots.homeHead, 'This is my corner.'),
      (TourSpots.homeAfter, 'The modules after it wait here'),
      (TourSpots.band, 'The module to read now is always here'),
      (TourSpots.tabs, 'Down here are the tabs'),
    ];
    Offset? robotWas;
    for (final (i, (spot, words)) in steps.indexed) {
      expect(find.textContaining(words), findsOneWidget, reason: spot);
      expect(_says('${i + 1} / 4'), findsOneWidget);
      expect(_hole(tester), _spot(tester, spot).intersect(Offset.zero & const Size(393, 852)), reason: spot);
      final robot = tester.getCenter(_robot);
      expect(robot, isNot(robotWas), reason: 'it walked to $spot');
      robotWas = robot;
      expect(_says(i == 3 ? 'Got it' : 'Next'), findsOneWidget);
      await _tap(tester, _next);
    }

    expect(_scrim, findsNothing);
    expect(store.kept, const TourRecord(guiding: true, seen: {'home'}));
  });

  testWidgets('a tab opened the first time is shown, and not the second time', (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(guiding: true, seen: {'home'}));
    expect(_scrim, findsNothing, reason: 'Home was shown');

    await _tap(tester, find.text('Catalog').last);
    expect(find.textContaining('Look for any topic here.'), findsOneWidget);
    expect(_says('1 / 2'), findsOneWidget);
    await _tap(tester, _next);
    expect(find.textContaining('Every level and its modules'), findsOneWidget);
    await _tap(tester, _next);
    expect(store.kept.seen, {'home', 'catalog'});

    await _tap(tester, find.text('Home').last);
    await _tap(tester, find.text('Catalog').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('Skip leaves the page shown, and the other tabs still to show', (tester) async {
    final (_, store) = await _pump(
      tester,
      record: const TourRecord(guiding: true, seen: {'home'}),
      at: '/quiz',
    );
    expect(find.textContaining('quizzes are here'), findsOneWidget);

    await _tap(tester, _skip);
    expect(_scrim, findsNothing);
    expect(store.kept.seen, {'home', 'quiz'});

    await _tap(tester, find.text('Caravan').last);
    expect(find.textContaining('The Caravan travels'), findsOneWidget);
  });

  testWidgets('Settings: the reading choices, then the way to the guide', (tester) async {
    final (_, store) = await _pump(
      tester,
      record: const TourRecord(guiding: true, seen: {'home', 'catalog', 'caravan', 'quiz'}),
      at: '/settings',
    );
    expect(find.textContaining('Your track, the app'), findsOneWidget);
    await _tap(tester, _next);
    expect(find.textContaining('Want this tour again?'), findsOneWidget);
    expect(_hole(tester), isNotNull, reason: 'the guide row was scrolled into view');
    await _tap(tester, _next);
    expect(store.kept.seen, hasLength(5));
  });

  testWidgets('with reduced motion the Apprentice is at its place at once', (tester) async {
    await _pump(tester, record: const TourRecord(guiding: true), reduced: true);

    final head = _spot(tester, TourSpots.homeHead);
    expect(tester.getRect(_robot).top, closeTo(head.bottom - TourLayer.robotSize / 3, 1));
  });

  testWidgets('a screen reader hears only the Apprentice while it speaks', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, record: const TourRecord(guiding: true));

    expect(find.semantics.byLabel(RegExp('This is my corner')), findsOne);
    expect(find.semantics.byLabel('Later on'), findsNothing, reason: 'the page under it is left out');
    handle.dispose();
  });
}

/// The app with animations turned off, as a reader with reduced motion has it.
class _Reduced extends StatelessWidget {
  const _Reduced({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MediaQuery(data: MediaQueryData.fromView(View.of(context)).copyWith(disableAnimations: true), child: child);
}

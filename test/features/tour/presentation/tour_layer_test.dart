@Tags(['widget'])
library;

import 'dart:async';

import 'package:ai_engineering_bazaar/app/router/app_router.dart';
import 'package:ai_engineering_bazaar/app/router/app_routes_constants.dart';
import 'package:ai_engineering_bazaar/features/tour/application/tour_cubit.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:ai_engineering_bazaar/features/tour/presentation/tour_layer.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_page.dart';
import 'package:ai_engineering_bazaar/shared/tour/tour_target.dart';
import 'package:ai_engineering_bazaar/features/home/presentation/widgets/home_practice.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/study/application/study_notes_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/accessibility.dart';
import '../../../mocks/mock_classes.dart';
import '../../../support/bazaar_app_harness.dart';
import '../../../support/content_builders.dart';
import '../../welcome/presentation/welcome_track_fit_harness.dart' show loadFace, robotoFiles;

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
  MockContentRepository? repository,
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
  final app = bazaarTestApp(router: router, tour: tour, locale: locale, repository: repository);
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

/// How far along the page's places the dots say it is.
Finder _dots(int step, int count) =>
    find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == '$step of $count');

final _button = find.byKey(const ValueKey('pocket-assistant'));

/// Whether the floating button is drawn: it is left empty while the Apprentice is out.
bool _buttonDrawn(WidgetTester tester) =>
    tester.widget<Visibility>(find.ancestor(of: _button, matching: find.byType(Visibility)).first).visible;

/// The rect the scrim leaves clear.
Rect? _hole(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(_scrim);
  return (paint.painter! as dynamic).hole as Rect?;
}

Rect _spot(WidgetTester tester, String spot) {
  final box = TourTarget.contextOf(spot)!.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

const _hello = "Hi, I'm the Apprentice. Shall I show you around?";

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

    await _tap(tester, find.text('Practice').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('the question is in Turkish too', (tester) async {
    await _pump(tester, record: const TourRecord(asking: true), locale: const Locale('tr'));

    expect(_says('Gezdir'), findsOneWidget);
    expect(_says('Şimdi değil'), findsOneWidget);
    expect(find.textContaining('Merhaba, ben Çırak.'), findsOneWidget);
  });

  testWidgets('said yes, it shows Home a place at a time, walking to each, and Home is done', (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(asking: true));

    await _tap(tester, find.byKey(const ValueKey('tour-accept')));
    expect(_asking, findsNothing);

    final steps = [
      (TourSpots.homeHead, 'I bring you a section every day.'),
      (TourSpots.band, 'The module to read now is always here.'),
      (TourSpots.tabs, "Open a tab and I'll show you around it."),
    ];
    Offset? robotWas;
    for (final (i, (spot, words)) in steps.indexed) {
      expect(find.textContaining(words), findsOneWidget, reason: spot);
      expect(_dots(i + 1, 3), findsOneWidget, reason: 'no stop at Later on (the owner, 2026-11-18)');
      expect(_hole(tester), _spot(tester, spot).intersect(Offset.zero & const Size(393, 852)), reason: spot);
      final robot = tester.getCenter(_robot);
      expect(robot, isNot(robotWas), reason: 'it walked to $spot');
      robotWas = robot;
      expect(_says(i == 2 ? 'Got it' : 'Next'), findsOneWidget);
      await _tap(tester, _next);
    }

    expect(_scrim, findsNothing);
    expect(store.kept, const TourRecord(guiding: true, seen: {'home'}));
  });

  testWidgets("with Practice on Home, it stops there after the day's card (the owner, 2026-11-18)", (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer(
      (_) async => testDoc(
        quiz: const [
          QuizItem(question: 'Q1', options: ['One', 'Two'], answer: 0, explain: 'E1'),
        ],
      ),
    );
    await _pump(tester, record: const TourRecord(guiding: true), repository: repository);

    expect(_dots(1, 4), findsOneWidget, reason: 'four places: the head, Practice, the band, the tabs');
    await _tap(tester, _next);
    expect(find.textContaining('A few questions and terms a day, and the glossary.'), findsOneWidget);
    expect(_hole(tester), _spot(tester, TourSpots.homePractice).intersect(Offset.zero & const Size(393, 852)));
    expect(_hole(tester)!.height, lessThan(300), reason: 'Practice alone');
  });

  // Review 6, finding 4: a place gone during the scroll to it left the dim layer over the whole screen, with no bubble
  // and no Skip, taking every touch.
  testWidgets('a place that goes while the tour scrolls to it is passed, not left as a dead screen', (tester) async {
    final repository = missingContentRepository();
    when(() => repository.readModuleDoc(any())).thenAnswer(
      (_) async => testDoc(
        quiz: const [
          QuizItem(question: 'Q1', options: ['One', 'Two'], answer: 0, explain: 'E1'),
        ],
      ),
    );
    await _pump(tester, record: const TourRecord(guiding: true), repository: repository);
    expect(_dots(1, 4), findsOneWidget);

    await tester.tap(_next);
    await tester.pump(const Duration(milliseconds: 50));
    // The notes reload under it, as a new content version makes them do: Home's Practice row is gone meanwhile.
    final element = tester.element(find.byType(HomePractice));
    final index = (element.read<ContentBloc>().state as ContentReady).index;
    unawaited(element.read<StudyNotesCubit>().load(index, Track.engineers, 'tr'));
    await _walk(tester);

    expect(_dots(3, 4), findsOneWidget, reason: 'on to the band');
    expect(_hole(tester), isNotNull);
  });

  for (final locale in const [Locale('en'), Locale('fa')]) {
    testWidgets("on Home's head it leaves Show another in sight, which the words name (${locale.languageCode})", (
      tester,
    ) async {
      final repository = missingContentRepository();
      when(() => repository.readModuleDoc(any())).thenAnswer(
        (_) async => testDoc(
          body: [
            const HeadingBlock(
              depth: 2,
              id: 'why',
              mark: null,
              inlines: [TextInline(text: 'Why tools')],
            ),
            const ParagraphBlock(inlines: [TextInline(text: 'Models call tools.')], lead: false),
          ],
        ),
      );
      await _pump(tester, record: const TourRecord(guiding: true), locale: locale, repository: repository);
      final another = tester.getRect(find.byKey(const ValueKey('home-daily-another')));
      expect(tester.getRect(_robot).overlaps(another), isFalse);
    });
  }

  // Review 8, finding 7: at the largest text the bubble ran below the screen with Skip and Next, and the scrim took
  // every other touch.
  for (final scale in [2.0, 3.0]) {
    for (final (page, at) in [('home', '/'), ('catalog', '/sheets'), ('settings', '/settings')]) {
      testWidgets('at text scale $scale, Skip and Next stay on the screen at every place of $page', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(
          tester,
          record: TourRecord(guiding: true, seen: {if (page != 'home') 'home'}),
          at: at,
          locale: const Locale('tr'),
        );

        final screen = Offset.zero & const Size(393, 852);
        var places = 0;
        while (_scrim.evaluate().isNotEmpty) {
          for (final button in [_skip, _next]) {
            final rect = tester.getRect(button);
            expect(
              screen.contains(rect.topLeft) && screen.contains(rect.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: 'place ${places + 1}: $button at $rect',
            );
          }
          places++;
          await _tap(tester, _next);
        }
        expect(places, greaterThan(0));
      });
    }
  }

  testWidgets("Android's Back while the tour points is Skip, and Back then goes on to the pages", (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(asking: true));
    await _tap(tester, find.byKey(const ValueKey('tour-accept')));
    expect(_scrim, findsOneWidget);

    await tester.binding.handlePopRoute();
    await _walk(tester);
    expect(_scrim, findsNothing);
    expect(store.kept.guiding, isFalse);
  });

  // Review 10, finding 4: a progress link's page over Home, as the website sends a new reader, took Back as Skip.
  testWidgets('Back on a page over the shell closes the page, and the question under it waits', (tester) async {
    final (router, store) = await _pump(tester, record: const TourRecord(asking: true));
    unawaited(router.push(BazaarPaths.transfer, extra: 'x'));
    await _walk(tester);
    expect(router.state.uri.path, BazaarPaths.transfer);

    await tester.binding.handlePopRoute();
    await _walk(tester);
    expect(router.state.uri.path, '/', reason: 'Back closes the page in front');
    expect(store.kept.asking, isTrue, reason: 'the question was never seen');
  });

  testWidgets('a tab opened the first time is shown, and not the second time', (tester) async {
    final (_, store) = await _pump(tester, record: const TourRecord(guiding: true, seen: {'home'}));
    expect(_scrim, findsNothing, reason: 'Home was shown');

    await _tap(tester, find.text('Catalog').last);
    expect(find.textContaining('Search any topic here.'), findsOneWidget);
    expect(_dots(1, 2), findsOneWidget);
    await _tap(tester, _next);
    expect(find.textContaining('Tap a level to see its modules.'), findsOneWidget);
    // The ring holds the first level whole, as Practice's first level, not the whole page (the owner, 2026-11-18).
    final ring = _hole(tester)!;
    expect(ring, _spot(tester, TourSpots.catalogLevels));
    expect(ring, tester.getRect(find.byKey(const ValueKey('catalog-level-alpha'))), reason: 'the first level, whole');
    expect(
      ring.bottom,
      lessThan(tester.getRect(find.byKey(const ValueKey('catalog-level-beta'), skipOffstage: false)).top),
      reason: 'the first level alone',
    );
    expect(tester.getRect(_next).bottom, lessThan(tester.getRect(find.byType(NavigationBar)).top - 60));
    await _tap(tester, _next);
    expect(store.kept.seen, {'home', 'catalog'});

    await _tap(tester, find.text('Home').last);
    await _tap(tester, find.text('Catalog').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('Skip ends the tour: no other tab is shown after it', (tester) async {
    final (_, store) = await _pump(
      tester,
      record: const TourRecord(guiding: true, seen: {'home'}),
      at: '/practice',
    );
    expect(find.textContaining('Practice here for as long as you like.'), findsOneWidget);

    await _tap(tester, _skip);
    expect(_scrim, findsNothing);
    expect(store.kept.guiding, isFalse);

    await _tap(tester, find.text('Caravan').last);
    expect(_scrim, findsNothing);
    await _tap(tester, find.text('Catalog').last);
    expect(_scrim, findsNothing);
  });

  testWidgets('taken again from the guide, Skip on a tab ends it there too', (tester) async {
    final (router, store) = await _pump(
      tester,
      record: const TourRecord(seen: {'home', 'catalog', 'caravan', 'practice', 'settings'}),
      at: '/settings/guide',
    );
    await _tap(tester, find.byKey(const ValueKey('guide-replay-tour')));
    await _tap(tester, _skip);
    expect(router.state.uri.path, '/');

    await _tap(tester, find.text('Catalog').last);
    expect(_scrim, findsNothing);
    await _tap(tester, find.text('Practice').last);
    expect(_scrim, findsNothing);
    expect(store.kept.guiding, isFalse);
  });

  testWidgets('it comes out of its floating button, which is empty meanwhile, and walks back into it', (tester) async {
    await _pump(
      tester,
      record: const TourRecord(guiding: true, seen: {'home'}),
      at: '/practice',
    );
    final button = tester.getRect(_button);

    expect(_robot, findsOneWidget);
    expect(_buttonDrawn(tester), isFalse, reason: 'one Apprentice on the screen');
    expect(tester.getRect(_robot).topLeft, isNot(button.topLeft), reason: 'it walked to the place');

    // Practice has two places: Today's review, then the first level.
    await _tap(tester, _next);
    expect(find.textContaining("Each level's quizzes."), findsOneWidget);
    await tester.tap(_next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_robot, findsOneWidget, reason: 'on its way home');
    expect(_buttonDrawn(tester), isFalse);
    await tester.pump(TourLayer.walk);
    await tester.pump();
    expect(_robot, findsNothing);
    expect(_buttonDrawn(tester), isTrue);
    expect(tester.getRect(_button), button);
  });

  testWidgets('asked and told Later, it goes back into its button', (tester) async {
    await _pump(tester, record: const TourRecord(asking: true));
    expect(_buttonDrawn(tester), isFalse);
    final seat = tester.getRect(_robot);
    expect(seat.center.dy, lessThan(tester.getRect(_button).top), reason: 'it came out to ask');

    await _tap(tester, find.byKey(const ValueKey('tour-later')));
    expect(_robot, findsNothing);
    expect(_buttonDrawn(tester), isTrue);
  });

  testWidgets('Settings: the reading choices, the wardrobe, the website, then the guide, which takes the tour again '
      'from Home', (tester) async {
    final (router, store) = await _pump(
      tester,
      record: const TourRecord(guiding: true, seen: {'home', 'catalog', 'caravan', 'practice'}),
      at: '/settings',
    );
    expect(find.textContaining('Audience, language, appearance and text size.'), findsOneWidget);
    await _tap(tester, _next);
    expect(find.textContaining('My wardrobe:'), findsOneWidget);
    expect(_dots(2, 4), findsOneWidget);
    await _tap(tester, _next);
    // Plan 17.1: how progress moves between the app and the website.
    expect(find.textContaining('Bring your progress from the website here'), findsOneWidget);
    expect(_hole(tester), isNotNull, reason: 'the website section was scrolled into view');
    expect(_dots(3, 4), findsOneWidget);
    await _tap(tester, _next);
    expect(find.textContaining('This tour waits in How the bazaar works.'), findsOneWidget);
    expect(_hole(tester), isNotNull, reason: 'the guide row was scrolled into view');
    await _tap(tester, _next);
    expect(store.kept.seen, hasLength(5));
    // The owner, 2026-11-17: the tour ends here, so the Apprentice walks back into a button Settings now has.
    await tester.pump(TourLayer.walk);
    await tester.pump();
    expect(_robot, findsNothing);
    expect(_button, findsOneWidget);
    expect(_buttonDrawn(tester), isTrue);

    router.push(ApplicationRoutesConstants.guide);
    await _walk(tester);
    await _tap(tester, find.byKey(const ValueKey('guide-replay-tour')));

    expect(router.state.uri.path, '/');
    expect(find.textContaining('I bring you a section every day.'), findsOneWidget);
    expect(store.kept, const TourRecord(guiding: true));
  });

  // Plan 12.12: Settings' Reading grew a row and its rows moved onto one line; each stop still rings its whole place,
  // the Apprentice stays on the screen and Next stays above the navigation, measured in Roboto on a small Android and
  // an iPhone, in each language. Plan 17.1 adds the website's line between Customize and the guide.
  group('Settings\' stops in a real face', () {
    setUpAll(() => loadFace('Roboto', robotoFiles()));
    for (final (name, size, insets) in [
      ('393x852 iPhone', const Size(393, 852), (62.0, 34.0)),
      ('360x800 Android', const Size(360, 800), (24.0, 24.0)),
    ]) {
      for (final locale in const [Locale('en'), Locale('tr'), Locale('fa')]) {
        testWidgets('on a $name in ${locale.languageCode}', (tester) async {
          await _pump(
            tester,
            record: const TourRecord(guiding: true, seen: {'home', 'catalog', 'caravan', 'practice'}),
            at: '/settings',
            locale: locale,
          );
          tester.view.physicalSize = size;
          tester.view.padding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
          tester.view.viewPadding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
          addTearDown(tester.view.reset);
          await _walk(tester);
          final screen = Offset.zero & size;
          for (final spot in TourPage.settings.spots) {
            await _walk(tester);
            final hole = _hole(tester)!;
            final place = _spot(tester, spot);
            expect(hole.height, moreOrLessEquals(place.height, epsilon: 1), reason: '$spot: the whole place ringed');
            expect(screen.contains(tester.getRect(_robot).topLeft), isTrue, reason: '$spot: the Apprentice on screen');
            final next = tester.getRect(_next);
            expect(next.bottom, lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy), reason: spot);
            if (spot != TourSpots.settingsGuide) await _tap(tester, _next);
          }
        });
      }
    }
  });

  // Plan 13.11: the Quiz tab's stop gave way to Practice's two, the endless review, then the first level; each rings
  // its whole place, with the Apprentice on the screen and Next above the navigation, in each language.
  group("Practice's stops in a real face", () {
    setUpAll(() => loadFace('Roboto', robotoFiles()));
    for (final (name, size, insets) in [
      ('393x852 iPhone', const Size(393, 852), (62.0, 34.0)),
      ('360x800 Android', const Size(360, 800), (24.0, 24.0)),
    ]) {
      for (final locale in const [Locale('en'), Locale('tr'), Locale('fa')]) {
        testWidgets('on a $name in ${locale.languageCode}', (tester) async {
          // Modules with a quiz, so the endless review shows Start, as on a phone.
          final repository = missingContentRepository();
          when(() => repository.readModuleDoc(any())).thenAnswer(
            (_) async => testDoc(
              quiz: const [
                QuizItem(question: 'Q1', options: ['One', 'Two'], answer: 0, explain: 'E1'),
              ],
            ),
          );
          // The phone's insets from the start, as on a phone: set after, the ring was left where the page stood.
          tester.view.padding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
          tester.view.viewPadding = FakeViewPadding(top: insets.$1, bottom: insets.$2);
          addTearDown(tester.view.reset);
          await _pump(
            tester,
            record: const TourRecord(guiding: true, seen: {'home', 'catalog', 'caravan', 'settings'}),
            at: '/practice',
            locale: locale,
            repository: repository,
          );
          tester.view.physicalSize = size;
          await _walk(tester);
          final screen = Offset.zero & size;
          for (final spot in [TourSpots.practiceToday, TourSpots.quizLevel]) {
            await _walk(tester);
            final hole = _hole(tester)!;
            final place = _spot(tester, spot);
            expect(hole.height, moreOrLessEquals(place.height, epsilon: 1), reason: '$spot: the whole place ringed');
            expect(hole.top, moreOrLessEquals(place.top, epsilon: 1), reason: '$spot: on its place');
            expect(screen.contains(tester.getRect(_robot).topLeft), isTrue, reason: '$spot: the Apprentice on screen');
            final next = tester.getRect(_next);
            expect(next.bottom, lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy), reason: spot);
            if (spot == TourSpots.practiceToday) {
              // The first stop rings the endless review alone: with the tiles in it, the Apprentice stood on
              // "Wrong answers" on a small phone (the owner's round, 2026-11-18).
              expect(place, tester.getRect(find.byKey(const Key('practice-endless'))));
              for (final part in [
                find.byIcon(Icons.all_inclusive_rounded),
                find.byKey(const Key('practice-endless-start')),
              ]) {
                expect(
                  tester.getRect(_robot).overlaps(tester.getRect(part)),
                  isFalse,
                  reason: '$part in view ${tester.getRect(_robot)} ${tester.getRect(part)} $place $hole',
                );
              }
            }
            if (spot != TourSpots.quizLevel) await _tap(tester, _next);
          }
        });
      }
    }
  });

  testWidgets('with reduced motion the Apprentice is at its place at once', (tester) async {
    await _pump(tester, record: const TourRecord(guiding: true), reduced: true);

    final head = _spot(tester, TourSpots.homeHead);
    expect(tester.getRect(_robot).top, closeTo(head.bottom - TourLayer.robotSize / 5, 1));
  });

  testWidgets('a screen reader hears only the Apprentice while it speaks', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, record: const TourRecord(guiding: true));

    expect(find.semantics.byLabel(RegExp('I bring you a section every day')), findsOne);
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

import 'dart:io';

import 'package:ai_engineering_bazaar/app/app.dart';
import 'package:ai_engineering_bazaar/app/di/app_dependencies.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The production wiring with three changes: the content site is an https address that refuses the connection at once,
/// so every refresh fails as `network` and the app runs on the bundled snapshot; the content cache lives in
/// `<directory>/cache`; and the record lives in `<directory>/record/`.
class _DeviceDependencies extends AppDependencies {
  _DeviceDependencies(this.directory)
    : super(
        appConfig: const AppConfig.test(contentBaseUrl: 'https://127.0.0.1:9/'),
        cacheDirectory: () async => Directory('${directory.path}/cache')..createSync(recursive: true),
      );

  final Directory directory;

  @override
  IRecordRepository createRecordRepository() => FileRecordRepository(baseDirectory: () async => directory);
}

/// Pumps the whole app over [directory]; nothing an earlier run left on the device reaches it.
///
/// The logger is configured as the bootstrap configures it outside production, since the device tests start the app
/// without the bootstrap and without the `test/` bootstrap.
Future<void> pumpDeviceApp(WidgetTester tester, {required Directory directory}) async {
  AppLogger.configure(isProduction: false);
  await tester.pumpWidget(App(dependencies: _DeviceDependencies(directory)));
}

B? _maybeBlocOf<B extends BlocBase<Object?>>(WidgetTester tester) {
  final provider = find.byWidgetPredicate((widget) => widget is BlocProvider<B>);
  if (provider.evaluate().isEmpty) return null;
  // The provider's own elements (the BlocProvider, its InheritedProvider and the inherited scope) cannot read what they
  // provide, so the bloc is read from the first element below them in the provider's single-child chain.
  var element = tester.element(provider.first);
  for (var depth = 0; depth < 8; depth++) {
    Element? child;
    element.visitChildren((candidate) => child ??= candidate);
    if (child == null) break;
    element = child!;
    try {
      return element.read<B>();
    } on ProviderNotFoundException {
      continue;
    }
  }
  throw StateError('no element below BlocProvider<$B> reads it');
}

/// The bloc of type [B] the first `BlocProvider<B>` in the tree provides.
B blocOf<B extends BlocBase<Object?>>(WidgetTester tester) =>
    _maybeBlocOf<B>(tester) ?? (throw StateError('no BlocProvider<$B> in the tree'));

/// Pumps every 100 ms until the state of the [B] in the tree satisfies [done], and returns that state.
Future<S> pumpUntil<B extends BlocBase<S>, S>(
  WidgetTester tester,
  bool Function(S state) done, {
  Duration timeout = const Duration(seconds: 90),
}) async {
  final stopwatch = Stopwatch()..start();
  S? last;
  while (stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    final bloc = _maybeBlocOf<B>(tester);
    if (bloc == null) continue;
    final state = bloc.state;
    last = state;
    if (done(state)) return state;
  }
  fail('timed out after $timeout waiting on $B; last state: $last');
}

GoRouter _router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Navigator).first));

/// Navigates the app's router to [location].
void goTo(WidgetTester tester, String location) => _router(tester).go(location);

/// The path of the router's current location.
String currentPath(WidgetTester tester) => _router(tester).routerDelegate.currentConfiguration.uri.path;

/// The text of [inlines] as the reader draws it, without its marks.
String plainText(List<Inline> inlines) => inlines.map(_plainText).join();

String _plainText(Inline inline) => switch (inline) {
  TextInline(:final text) || CodeInline(:final text) => text,
  StrongInline(:final inlines) ||
  EmphasisInline(:final inlines) ||
  DeleteInline(:final inlines) ||
  LinkInline(:final inlines) ||
  UnknownInline(:final inlines) => plainText(inlines),
  BreakInline() => ' ',
  LogoInline() => '',
};

final _whitespace = RegExp(r'\s+');

String _normalised(String text) => text.replaceAll('\uFFFC', '').replaceAll(_whitespace, ' ').trim().toLowerCase();

/// Every `RichText` whose text contains [text], ignoring case, placeholders (a logo span) and runs of whitespace.
Finder findProse(String text) {
  final wanted = _normalised(text);
  return find.byWidgetPredicate(
    (widget) => widget is RichText && _normalised(widget.text.toPlainText()).contains(wanted),
    description: 'prose containing "$text"',
  );
}

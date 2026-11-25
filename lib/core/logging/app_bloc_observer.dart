import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';

/// Central [BlocObserver] that routes BLoC lifecycle events through
/// [AppLogger].
///
/// Logs only runtime types (not stringified content) to avoid leaking
/// sensitive fields like passwords or tokens that may be carried on
/// events or held in states with `stringify = true`. BLoCs that need
/// to log specific content should do so explicitly inside their event
/// handlers with whitelisted fields.
///
/// Install once at app startup via `Bloc.observer = AppBlocObserver()`.
/// Other observers (e.g. dev console, analytics) can extend this class
/// to inherit logging while adding their own behaviour.
///
/// [report] hears every error a bloc reports with `addError` (opus review 11, arch finding 1): the blocs that catch a
/// fault of the app's own on purpose (RecordBloc, ModuleReaderBloc, AboutBloc, PocketModelBloc) reach crash reporting
/// only through it. An error thrown out of a handler reaches it too, and the zone as well; Sentry's deduplication of
/// the same exception keeps that to one report.
class AppBlocObserver extends BlocObserver {
  AppBlocObserver({this.report});

  static final _log = AppLogger.getLogger('Bloc');

  /// Where a bloc's error goes beyond the log: Sentry's capture in a release built with a DSN, nothing otherwise.
  final void Function(Object error, StackTrace stackTrace)? report;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log.trace('onCreate: {}', [bloc.runtimeType]);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log.trace('onTransition: {} | event={} | {} -> {}', [
      bloc.runtimeType,
      transition.event.runtimeType,
      transition.currentState.runtimeType,
      transition.nextState.runtimeType,
    ]);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log.trace('onChange: {} | {} -> {}', [
      bloc.runtimeType,
      change.currentState.runtimeType,
      change.nextState.runtimeType,
    ]);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _log.error('onError: {} | {}', [bloc.runtimeType, error]);
    report?.call(error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log.trace('onClose: {}', [bloc.runtimeType]);
  }
}

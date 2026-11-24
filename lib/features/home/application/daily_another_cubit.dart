import 'package:flutter_bloc/flutter_bloc.dart';

/// How many times Show another was pressed on Home's card, and on which day: above the page, so a tab switch does not
/// bring the day's first card back (review 11, features 7). In memory: a new launch starts at the day's first card.
final class DailyAnotherCubit extends Cubit<({int day, int another})> {
  DailyAnotherCubit() : super((day: 0, another: 0));

  /// The presses on [day]; none on any other day.
  int on(int day) => state.day == day ? state.another : 0;

  /// One more press on [day].
  void another(int day) => emit((day: day, another: on(day) + 1));
}

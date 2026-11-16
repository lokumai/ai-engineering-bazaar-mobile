import 'package:flutter_bloc/flutter_bloc.dart';

/// The pocket model's level (plan 9.10), from 0: shared, because the app icons unlock with the robot's wardrobe and
/// the app icon choice, which Settings and Welcome show, may not read the pocket model. [load] reads the level kept on
/// this device; `lib/app/di/` passes the reader and tells it each level the model reaches ([reached]).
final class RobotLevelCubit extends Cubit<int> {
  RobotLevelCubit({this._read}) : super(0);

  final Future<int> Function()? _read;
  bool _told = false;

  /// Reads the kept level, unless the model already told one.
  Future<void> load() async {
    final level = await _read?.call();
    if (level == null || isClosed || _told) return;
    emit(level);
  }

  /// The model reached [level], or went back to it on starting over.
  void reached(int level) {
    _told = true;
    if (!isClosed) emit(level);
  }
}

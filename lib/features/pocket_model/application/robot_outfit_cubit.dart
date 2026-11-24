import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_engineering_bazaar/shared/utils/serial_writes.dart';

/// The outfit the reader chose for the robot (plan 9.9), kept on this device. A `Cubit`: each choice is one atomic
/// call, and the event stream adds nothing. It keeps what was chosen; what the robot wears at its level is
/// [RobotOutfit.within].
final class RobotOutfitCubit extends Cubit<RobotOutfit> {
  RobotOutfitCubit({required this._store}) : super(RobotOutfit.initial);

  final IRobotOutfitStore _store;

  final _writes = SerialWrites();

  /// Whether the reader chose before the kept outfit was read: the read then does not undo it (review 11,
  /// architecture 8).
  bool _chosen = false;

  /// Reads the kept outfit, if there is one.
  Future<void> load() async {
    final kept = await _store.load();
    if (kept != null && !isClosed && !_chosen) emit(kept);
  }

  /// Puts [part] on: a hat, a head or a body.
  Future<void> wear(Enum part) async {
    final outfit = switch (part) {
      RobotHat() => state.copyWith(hat: part),
      RobotHead() => state.copyWith(head: part),
      RobotBody() => state.copyWith(body: part),
      _ => state,
    };
    _chosen = true;
    if (outfit == state) return;
    emit(outfit);
    await _writes.run(() => _store.save(outfit));
  }
}

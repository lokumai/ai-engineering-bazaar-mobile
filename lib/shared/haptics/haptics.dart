import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The touch feedback the app plays: a selection's tick and three taps by weight.
enum HapticKind { selection, light, medium, heavy }

/// The phone's touch feedback (plan 18.12). On iOS it is Flutter's own [HapticFeedback], the taps of UIKit; on Android
/// it is the app's channel, since Flutter's maps them to keyboard and clock ticks many phones play faintly or not at
/// all, held as soft as the iPhone's.
abstract interface class IHaptics {
  Future<void> play(HapticKind kind);
}

/// Flutter's own [HapticFeedback]: iOS's taps, and where no [IHaptics] is provided.
final class FlutterHaptics implements IHaptics {
  const FlutterHaptics();

  @override
  Future<void> play(HapticKind kind) => switch (kind) {
    HapticKind.selection => HapticFeedback.selectionClick(),
    HapticKind.light => HapticFeedback.lightImpact(),
    HapticKind.medium => HapticFeedback.mediumImpact(),
    HapticKind.heavy => HapticFeedback.heavyImpact(),
  };
}

extension HapticsOf on BuildContext {
  /// Plays [kind] with the [IHaptics] the app provides, or Flutter's own where none is, as in a widget's own test.
  void haptic(HapticKind kind) {
    IHaptics haptics;
    try {
      haptics = read<IHaptics>();
    } on ProviderNotFoundException {
      haptics = const FlutterHaptics();
    }
    haptics.play(kind).ignore();
  }
}

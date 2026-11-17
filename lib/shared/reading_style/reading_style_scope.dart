import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Draws [child] in the reader's reading settings (plan 12.5): its text at the chosen size on top of the phone's own
/// text size, and the body's lines at the chosen spacing. The reader wraps a module's text in it; the menus never.
class ReadingStyleScope extends StatelessWidget {
  const ReadingStyleScope({super.key, required this.child, this.style});

  final Widget child;

  /// The style to draw in; null takes the [ReadingStyleCubit]'s.
  final ReadingStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.watch<ReadingStyleCubit>().state;
    final scaler = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: style.size == ReadingSize.standard ? scaler : _Scaled(scaler, style.size.factor)),
      child: ReadingLines(height: style.spacing.lineHeight, child: child),
    );
  }
}

/// [base] with every size multiplied by [factor].
@immutable
final class _Scaled extends TextScaler {
  const _Scaled(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use, the interface still asks for it
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is _Scaled && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

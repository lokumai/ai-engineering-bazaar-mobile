import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A logo at text height, 1.1 times [fontSize] (the web's `height: 1.1em`), out of semantics: the name beside it says
/// what it is, and the bundle's alt is always empty.
///
/// A [mono] logo is a black mark the web inverts on a dark ground (`filter: invert(1)`); this is a full colour-matrix
/// invert, not a tint, because some mono marks hold white parts that a tint would lose.
class LogoView extends StatelessWidget {
  const LogoView({super.key, required this.src, required this.mono, required this.fontSize});

  final String src;
  final bool mono;
  final double fontSize;

  /// The key of the empty square drawn for a logo that is missing or does not parse.
  static const unreadableKey = Key('logo-unreadable');

  static const _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final height = 1.1 * fontSize;
    final invert = mono && Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: ContentObjectBuilder(
        sitePath: src,
        builder: (context, bytes) {
          final picture = SvgPicture.memory(
            bytes,
            height: height,
            // A logo SVG the parser rejects keeps its square of space, as a missing one does (plan 2.2).
            errorBuilder: (_, _, _) => SizedBox(key: unreadableKey, width: height, height: height),
          );
          return invert ? ColorFiltered(colorFilter: _invert, child: picture) : picture;
        },
        unreadable: (context) => SizedBox(key: unreadableKey, width: height, height: height),
      ),
    );
  }
}

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// A raster figure from the content store (spec 3.4.7), in the space its block's `width` and `height` reserve before
/// the bytes arrive, with the block's alt text as its label. A missing, corrupt or undecodable object shows the alt
/// text and the unreadable line in the same space. An animated WebP animates.
class FigureImage extends StatelessWidget {
  const FigureImage({super.key, required this.block});

  final ImageBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    const radius = BorderRadius.all(BazaarRadii.lg);
    // A DecoratedBox, not a Container: a Container's decoration padding would inset the figure by the border.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: block.width / block.height,
          child: ContentObjectBuilder(
            sitePath: block.src,
            placeholder: ColoredBox(color: colors.surfaceSunken),
            builder: (context, bytes) => Image.memory(
              bytes,
              fit: BoxFit.contain,
              semanticLabel: block.alt,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => ContentUnreadable(alt: block.alt),
            ),
            unreadable: (context) => ContentUnreadable(alt: block.alt),
          ),
        ),
      ),
    );
  }
}

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// A raster figure from the content store (spec 3.4.7), in the space its block's `width` and `height` reserve before
/// the bytes arrive, with the block's alt text as its label. A missing, corrupt or undecodable object shows the alt
/// text and the unreadable line in at least that space, taller when large text needs it. An animated WebP animates.
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final reserved = width * block.height / block.width;
            // Spec 3.10: the reserved height is a minimum, so the unreadable state can grow at large text.
            Widget unreadable() => ConstrainedBox(
              constraints: BoxConstraints(minWidth: width, minHeight: reserved),
              child: ContentUnreadable(alt: block.alt),
            );
            return ContentObjectBuilder(
              sitePath: block.src,
              placeholder: SizedBox(
                width: width,
                height: reserved,
                child: ColoredBox(color: colors.surfaceSunken),
              ),
              builder: (context, bytes) => Image.memory(
                bytes,
                width: width,
                height: reserved,
                fit: BoxFit.contain,
                semanticLabel: block.alt,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => unreadable(),
              ),
              unreadable: (context) => unreadable(),
            );
          },
        ),
      ),
    );
  }
}

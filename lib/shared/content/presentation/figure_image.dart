import 'dart:async';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/image_full_screen.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// A raster figure from the content store (spec 3.4.7), in the space its block's `width` and `height` reserve before
/// the bytes arrive, with the block's alt text as its label. A missing, corrupt or undecodable object shows the alt
/// text and the unreadable line in at least that space, taller when large text needs it. An animated WebP animates.
///
/// A tap on a drawn image opens it full screen ([ImageFullScreen]) to zoom and turn it, which a mark in its corner says
/// (plan 7.2), as a diagram does.
class FigureImage extends StatelessWidget {
  const FigureImage({super.key, required this.block});

  final ImageBlock block;

  /// The key of the mark that says the image opens full screen.
  static const expandKey = Key('image-expand');

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
                // Only an image that decoded opens full screen; one that does not shows the unreadable state.
                frameBuilder: (context, child, frame, _) =>
                    frame == null ? child : _Openable(bytes: bytes, alt: block.alt, child: child),
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

/// A drawn image as the button that opens it full screen, with the mark in its corner.
class _Openable extends StatelessWidget {
  const _Openable({required this.bytes, required this.alt, required this.child});

  final Uint8List bytes;
  final String alt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void open() => unawaited(ImageFullScreen.open(context, bytes: bytes, label: alt));
    // One node: the image named by its alt text, which is also the button that opens it.
    return Semantics(
      container: true,
      image: true,
      button: true,
      label: alt,
      hint: S.of(context).image_expand,
      onTap: open,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              child,
              // Says the image opens larger: a tap anywhere on it does. A dark disc keeps it seen on any photo.
              const PositionedDirectional(
                top: 6,
                end: 6,
                child: DecoratedBox(
                  key: FigureImage.expandKey,
                  decoration: BoxDecoration(color: Color(0x8A000000), shape: BoxShape.circle),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.open_in_full, size: 16, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

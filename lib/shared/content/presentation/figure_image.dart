import 'dart:async';
import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/image_full_screen.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/utils/animated_image.dart';
import 'package:flutter/material.dart';

/// A raster figure from the content store (spec 3.4.7), in the space its block's `width` and `height` reserve before
/// the bytes arrive, with the block's alt text as its label. A missing, corrupt or undecodable object shows the alt
/// text and the unreadable line in at least that space, taller when large text needs it. An animated WebP animates,
/// and a button over its top corner plays it again from its start, as the web's replay control does (web M115, D136).
///
/// A tap on a drawn image opens it full screen ([ImageFullScreen]) to zoom and turn it, which a mark in its corner says
/// (plan 7.2), as a diagram does.
class FigureImage extends StatelessWidget {
  const FigureImage({super.key, required this.block});

  final ImageBlock block;

  /// The key of the mark that says the image opens full screen.
  static const expandKey = Key('image-expand');

  /// The key of the button that plays an animated image again.
  static const replayKey = Key('image-replay');

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
              builder: (context, bytes) =>
                  _Drawn(bytes: bytes, width: width, height: reserved, alt: block.alt, unreadable: unreadable),
              unreadable: (context) => unreadable(),
            );
          },
        ),
      ),
    );
  }
}

/// The image of [bytes] once read; an animated one counts its plays, and each replay draws it afresh.
class _Drawn extends StatefulWidget {
  const _Drawn({
    required this.bytes,
    required this.width,
    required this.height,
    required this.alt,
    required this.unreadable,
  });

  final Uint8List bytes;
  final double width;
  final double height;
  final String alt;
  final Widget Function() unreadable;

  @override
  State<_Drawn> createState() => _DrawnState();
}

class _DrawnState extends State<_Drawn> {
  late final bool _animated = isAnimatedImage(widget.bytes);
  var _plays = 0;

  /// The image decoded at the width it is drawn at, in device pixels, and never wider than it is: a photo of 2000
  /// pixels drawn 360 wide on a phone of ratio 3 is decoded 1080 wide, which looks the same and takes a third of the
  /// width in memory. The full-screen view decodes it whole, to zoom.
  ImageProvider _image(BuildContext context) => widget.width.isFinite
      ? ResizeImage(
          MemoryImage(widget.bytes),
          width: (widget.width * MediaQuery.devicePixelRatioOf(context)).ceil(),
          policy: ResizeImagePolicy.fit,
        )
      : MemoryImage(widget.bytes);

  /// Starts the animation from its first frame: the image cache keeps an animation's playhead with its decoded image,
  /// so the image is put out of the cache and read again under a new key.
  void _replay() {
    unawaited(_image(context).evict());
    setState(() => _plays++);
  }

  @override
  Widget build(BuildContext context) => Image(
    image: _image(context),
    key: ValueKey(_plays),
    width: widget.width,
    height: widget.height,
    fit: BoxFit.contain,
    semanticLabel: widget.alt,
    gaplessPlayback: true,
    // Only an image that decoded opens full screen; one that does not shows the unreadable state.
    frameBuilder: (context, child, frame, _) => frame == null
        ? child
        : _Openable(bytes: widget.bytes, alt: widget.alt, onReplay: _animated ? _replay : null, child: child),
    errorBuilder: (_, _, _) => widget.unreadable(),
  );
}

/// A drawn image as the button that opens it full screen, with the mark in its corner, and the replay button beside
/// it when [onReplay] is given.
class _Openable extends StatelessWidget {
  const _Openable({required this.bytes, required this.alt, required this.child, this.onReplay});

  final Uint8List bytes;
  final String alt;
  final Widget child;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    void open() => unawaited(ImageFullScreen.open(context, bytes: bytes, label: alt));
    final onReplay = this.onReplay;
    // One node: the image named by its alt text, which is also the button that opens it.
    final openable = Semantics(
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
    if (onReplay == null) return openable;
    return Stack(
      children: [
        openable,
        // Beside the full-screen mark and level with it: a disc of its size in a tap target of 48.
        PositionedDirectional(
          top: 0,
          end: 26,
          child: Tooltip(
            message: S.of(context).image_replay,
            child: Semantics(
              button: true,
              label: S.of(context).image_replay,
              onTap: onReplay,
              excludeSemantics: true,
              child: GestureDetector(
                key: FigureImage.replayKey,
                onTap: onReplay,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x8A000000), shape: BoxShape.circle),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.replay, size: 16, color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

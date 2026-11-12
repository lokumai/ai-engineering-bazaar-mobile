import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/utils/animated_image.dart';
import 'package:ai_engineering_bazaar/shared/utils/app_orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A photo or an animated image over the whole screen, to see it at a size the page cannot give it (plan 7.2), as a
/// diagram opens ([DiagramFullScreen]): on a black ground, it fills the screen, pinch zooms up to six times and pans,
/// and turns with the phone, which the rest of the app does not. An animated WebP keeps playing, and a replay button in
/// the top corner plays it again from its start, as on the page (web D136). The close button goes back to the page.
class ImageFullScreen extends StatefulWidget {
  const ImageFullScreen({super.key, required this.bytes, required this.label});

  /// The image as drawn in the page.
  final Uint8List bytes;

  /// The image's alt text, which names it for assistive technology.
  final String label;

  /// The key of the button that plays an animated image again.
  static const replayKey = Key('image-full-screen-replay');

  /// The ground behind the image.
  static const ground = Color(0xFF000000);

  /// Opens the image full screen over the whole app.
  static Future<void> open(BuildContext context, {required Uint8List bytes, required String label}) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ImageFullScreen(bytes: bytes, label: label),
        ),
      );

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen> {
  late final bool _animated = isAnimatedImage(widget.bytes);
  var _plays = 0;

  /// Starts the animation from its first frame, as the page's replay does: out of the image cache, then a new key.
  void _replay() {
    unawaited(MemoryImage(widget.bytes).evict());
    setState(() => _plays++);
  }

  @override
  void initState() {
    super.initState();
    // A wide image reads best across the phone.
    unawaited(SystemChrome.setPreferredOrientations(const []));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(appOrientations()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImageFullScreen.ground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                image: true,
                label: widget.label,
                child: ExcludeSemantics(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 56, 0, 12),
                      child: Image.memory(
                        widget.bytes,
                        key: ValueKey(_plays),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const PositionedDirectional(top: 4, start: 4, child: CloseButton(color: Colors.white)),
            if (_animated)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: IconButton(
                  key: ImageFullScreen.replayKey,
                  tooltip: S.of(context).image_replay,
                  color: Colors.white,
                  onPressed: _replay,
                  icon: const Icon(Icons.replay),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A photo or an animated image over the whole screen, to see it at a size the page cannot give it (plan 7.2), as a
/// diagram opens ([DiagramFullScreen]): on a black ground, it fills the screen, pinch zooms up to six times and pans,
/// and turns with the phone, which the rest of the app does not. An animated WebP keeps playing. The close button goes
/// back to the page.
class ImageFullScreen extends StatefulWidget {
  const ImageFullScreen({super.key, required this.bytes, required this.label});

  /// The image as drawn in the page.
  final Uint8List bytes;

  /// The image's alt text, which names it for assistive technology.
  final String label;

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

  /// The orientations of the app, which it takes back on leaving (`AppBootstrapConfig.preferredOrientations`).
  static const appOrientations = [DeviceOrientation.portraitUp];

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen> {
  @override
  void initState() {
    super.initState();
    // A wide image reads best across the phone.
    unawaited(SystemChrome.setPreferredOrientations(const []));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(ImageFullScreen.appOrientations));
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
                      child: Image.memory(widget.bytes, fit: BoxFit.contain, gaplessPlayback: true),
                    ),
                  ),
                ),
              ),
            ),
            const PositionedDirectional(top: 4, start: 4, child: CloseButton(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

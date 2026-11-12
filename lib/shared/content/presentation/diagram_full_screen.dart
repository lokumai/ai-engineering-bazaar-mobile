import 'dart:async';

import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/utils/app_orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A diagram over the whole screen, on its own ground, to read it at a size the page cannot give it (review findings,
/// B): it fills the screen, pinch zooms up to six times and pans, and turns with the phone, which the rest of the app
/// does not. The close button goes back to the page.
class DiagramFullScreen extends StatefulWidget {
  const DiagramFullScreen({super.key, required this.bytes, required this.ground, required this.label});

  /// The SVG as drawn in the page.
  final Uint8List bytes;
  final DiagramTheme ground;

  /// The diagram's caption, which names it for assistive technology.
  final String label;

  /// Opens the diagram full screen over the whole app.
  static Future<void> open(
    BuildContext context, {
    required Uint8List bytes,
    required DiagramTheme ground,
    required String label,
  }) => Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DiagramFullScreen(bytes: bytes, ground: ground, label: label),
    ),
  );

  @override
  State<DiagramFullScreen> createState() => _DiagramFullScreenState();
}

class _DiagramFullScreenState extends State<DiagramFullScreen> {
  @override
  void initState() {
    super.initState();
    // A wide diagram reads best across the phone.
    unawaited(SystemChrome.setPreferredOrientations(const []));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(appOrientations()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ground = Color(widget.ground.backgroundArgb);
    final ink = ground.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Scaffold(
      backgroundColor: ground,
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
                      padding: const EdgeInsets.fromLTRB(12, 56, 12, 12),
                      child: SvgPicture.memory(widget.bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(top: 4, start: 4, child: CloseButton(color: ink)),
          ],
        ),
      ),
    );
  }
}

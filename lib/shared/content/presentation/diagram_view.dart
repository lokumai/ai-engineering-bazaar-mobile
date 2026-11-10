import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/captions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_full_screen.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A bundled diagram in its frame: `svg.light` on the light `diagramThemes` ground, or `svg.dark` on the dark one, with
/// the frame edge of that variant (A26), labelled with its caption. A tap anywhere on it opens it full screen
/// ([DiagramFullScreen]) to zoom and turn it, which a mark in its corner says (review findings, B: at a phone's width
/// its labels are too small to read). A diagram that is missing, corrupt or does not parse shows [ContentUnreadable].
///
/// [variant] defaults to light in both themes, as photos stay as they are in a dark theme (owner, 2026-11-10); the dev
/// console passes it to show both. The caption text under the frame is the block renderer's.
class DiagramView extends StatelessWidget {
  const DiagramView({super.key, required this.block, required this.themes, this.variant});

  final DiagramBlock block;
  final DiagramThemes themes;
  final DiagramVariant? variant;

  /// The key of the mark that says the diagram opens full screen.
  static const expandKey = Key('diagram-expand');

  @override
  Widget build(BuildContext context) {
    final variant = this.variant ?? DiagramVariant.light;
    final (path, ground) = switch (variant) {
      DiagramVariant.light => (block.svgLight, themes.light),
      DiagramVariant.dark => (block.svgDark, themes.dark),
    };
    final s = S.of(context);
    final label = figureCaption(s, number: block.number, title: block.title);
    final edge = DiagramFrameInk.of(variant).edge;
    // One node named by the caption from the start, while it loads and when it cannot be read; once drawn it is also
    // the button that opens it full screen, which merges into that node.
    return Semantics(
      container: true,
      image: true,
      label: label,
      child: DecoratedBox(
        key: const Key('diagram-frame'),
        decoration: BoxDecoration(
          color: Color(ground.backgroundArgb),
          border: Border.all(color: edge),
          borderRadius: const BorderRadius.all(BazaarRadii.lg),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => ContentObjectBuilder(
            sitePath: path,
            builder: (context, bytes) {
              void open() => unawaited(DiagramFullScreen.open(context, bytes: bytes, ground: ground, label: label));
              return Semantics(
                button: true,
                hint: s.diagram_expand,
                onTap: open,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    onTap: open,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                          child: SvgPicture.memory(
                            bytes,
                            width: constraints.maxWidth - 36,
                            // An SVG the parser rejects would otherwise leave an empty frame.
                            errorBuilder: (_, _, _) => const ContentUnreadable(),
                          ),
                        ),
                        // Says the diagram opens larger: a tap anywhere on it does.
                        PositionedDirectional(
                          top: 6,
                          end: 6,
                          child: Icon(Icons.open_in_full, key: DiagramView.expandKey, size: 18, color: edge),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            unreadable: (context) => const ExcludeSemantics(
              child: Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 18), child: ContentUnreadable()),
            ),
          ),
        ),
      ),
    );
  }
}

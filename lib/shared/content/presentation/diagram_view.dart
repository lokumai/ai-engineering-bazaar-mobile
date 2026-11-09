import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/captions.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A bundled diagram in its frame: `svg.light` on the light `diagramThemes` ground, or `svg.dark` on the dark one, with
/// the frame edge of that variant (A26), zoomable inside an [InteractiveViewer] and labelled with its caption. A
/// diagram that is missing, corrupt or does not parse shows [ContentUnreadable].
///
/// [variant] defaults to the theme's brightness, which in the app follows the system setting. The caption text under
/// the frame is the block renderer's.
class DiagramView extends StatelessWidget {
  const DiagramView({super.key, required this.block, required this.themes, this.variant});

  final DiagramBlock block;
  final DiagramThemes themes;
  final DiagramVariant? variant;

  @override
  Widget build(BuildContext context) {
    final variant =
        this.variant ?? (Theme.of(context).brightness == Brightness.dark ? DiagramVariant.dark : DiagramVariant.light);
    final (path, ground) = switch (variant) {
      DiagramVariant.light => (block.svgLight, themes.light),
      DiagramVariant.dark => (block.svgDark, themes.dark),
    };
    return Semantics(
      image: true,
      label: figureCaption(S.of(context), number: block.number, title: block.title),
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: const Key('diagram-frame'),
          decoration: BoxDecoration(
            color: Color(ground.backgroundArgb),
            border: Border.all(color: DiagramFrameInk.of(variant).edge),
            borderRadius: const BorderRadius.all(BazaarRadii.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: LayoutBuilder(
              builder: (context, constraints) => ContentObjectBuilder(
                sitePath: path,
                builder: (context, bytes) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SvgPicture.memory(
                    bytes,
                    width: constraints.maxWidth,
                    // An SVG the parser rejects would otherwise leave an empty frame.
                    errorBuilder: (_, _, _) => const ContentUnreadable(),
                  ),
                ),
                unreadable: (context) => const ContentUnreadable(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

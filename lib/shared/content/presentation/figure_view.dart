import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// An image or a diagram with its caption 9 below (`w3b` D and F.1): the label `FIG. {number}` in on-surface at
/// weight 600, then ` · {title}` in the muted ink (A14); its text equals `figureCaption`. An image's note follows 4
/// below in the muted ink. A diagram is already labelled with its caption by [DiagramView], so its visible caption is
/// not read a second time.
class FigureView extends StatelessWidget {
  FigureView.image({super.key, required ImageBlock block})
    : _figure = FigureImage(block: block),
      _number = block.number,
      _title = block.title,
      _note = block.note,
      _labelled = false;

  FigureView.diagram({super.key, required DiagramBlock block, required DiagramThemes themes})
    : _figure = DiagramView(block: block, themes: themes),
      _number = block.number,
      _title = block.title,
      _note = null,
      _labelled = true;

  final Widget _figure;
  final String _number;
  final String? _title;
  final String? _note;

  /// The figure already carries its caption as its semantics label.
  final bool _labelled;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final s = S.of(context);
    final title = _title;
    final note = _note;
    final caption = Text.rich(
      TextSpan(
        style: TextStyle(fontSize: BazaarType.meta.size, fontWeight: FontWeight.w400, color: colors.onSurfaceMuted),
        children: [
          TextSpan(
            text: s.block_figure_caption(_number),
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
          ),
          if (title != null && title.isNotEmpty) TextSpan(text: ' · $title'),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _figure,
        const SizedBox(height: 9),
        if (_labelled) ExcludeSemantics(child: caption) else Semantics(container: true, child: caption),
        if (note != null) ...[
          const SizedBox(height: 4),
          Semantics(
            container: true,
            child: Text(
              note,
              style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
            ),
          ),
        ],
      ],
    );
  }
}

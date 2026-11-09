import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/inline_text.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The web's external-link arrow, held to the label by a word joiner.
const _externalMark = '\u2060↗';

/// A callout card (`w3b` C.1): centred text inside a 2 px edge whose colour names the kind, an optional title, the
/// body, and an optional button for its link. There is no icon and no kind word for any kind; a warning is filled
/// with the caution colour and draws everything in on-caution. The card is a container named by its title.
class CalloutView extends StatelessWidget {
  const CalloutView({super.key, required this.block, required this.render});

  final CalloutBlock block;
  final BlockRenderContext render;

  /// The body paragraphs are capped at 52 characters, approximated as half the body size per character.
  static final double paragraphMaxWidth = 52 * 0.5 * BazaarType.body.size;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final warning = block.kind == CalloutKind.warning;
    final edge = switch (block.kind) {
      CalloutKind.important => colors.primary,
      CalloutKind.note => colors.lineStrong,
      CalloutKind.tip => BazaarFixedColors.success,
      CalloutKind.caution => colors.fault,
      CalloutKind.warning => BazaarFixedColors.onCaution,
    };
    final title = block.title;
    final action = block.action;
    return Semantics(
      key: const Key('callout'),
      container: true,
      explicitChildNodes: true,
      label: title == null ? null : inlinePlainText(title),
      child: Container(
        key: const Key('callout-card'),
        decoration: BoxDecoration(
          color: warning ? BazaarFixedColors.caution : colors.surfaceRaised,
          border: Border.all(color: edge, width: 2),
          borderRadius: BazaarShapes.leaf,
        ),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InlineText(
                  inlines: title,
                  style: TextStyle(
                    fontSize: warning ? BazaarType.section.size : BazaarType.subsection.size,
                    height: warning ? BazaarType.section.height : BazaarType.subsection.height,
                    fontWeight: FontWeight.w700,
                    color: warning ? BazaarFixedColors.onCaution : colors.onSurfaceTitle,
                  ),
                  onLink: render.onLink,
                  textAlign: TextAlign.center,
                ),
              ),
            ProseScope(
              ink: warning ? BazaarFixedColors.onCaution : null,
              textAlign: TextAlign.center,
              paragraphMaxWidth: paragraphMaxWidth,
              child: BlockList(blocks: block.blocks, render: render, nested: true),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Center(
                  child: _ActionButton(action: action, render: render),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The callout's link as a filled button; an external link keeps the web's arrow in the button's ink.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.render});

  final CalloutAction action;
  final BlockRenderContext render;

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(fontSize: BazaarType.control.size, fontWeight: FontWeight.w600);
    return FilledButton(
      onPressed: () => render.onLink(action.target),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
        minimumSize: Size(0, minTapTarget(Theme.of(context).platform)),
        textStyle: label,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: InlineText(
              inlines: action.inlines,
              style: label,
              onLink: render.onLink,
              textAlign: TextAlign.center,
            ),
          ),
          if (action.target is ExternalTarget) const ExcludeSemantics(child: Text(_externalMark)),
        ],
      ),
    );
  }
}

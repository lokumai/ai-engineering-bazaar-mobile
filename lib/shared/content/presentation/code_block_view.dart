import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// A code block on the slab (`w3b` F.1): a head strip naming the language, then the lines in mono, coloured by each
/// token's role and bold only where the bundle marks it (A17), scrolling sideways instead of wrapping. The slab
/// tokens are the same in both themes, so the slab is the dark Night slab in both. The block is a container named
/// `{language} code`, or `Program output` for output.
class CodeBlockView extends StatelessWidget {
  const CodeBlockView({super.key, required this.block});

  final CodeBlock block;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mono = monoFamily(Theme.of(context).platform);
    return Semantics(
      key: const Key('code-block'),
      container: true,
      explicitChildNodes: true,
      label: block.language == 'output' ? s.block_program_output : s.block_code_label(block.language),
      // Code reads left to right in a Persian module too (plan 1Q).
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          key: const Key('code-slab'),
          decoration: const BoxDecoration(
            color: BazaarFixedColors.slabSurface,
            border: Border.fromBorderSide(BorderSide(color: BazaarFixedColors.slabLine)),
            borderRadius: BorderRadius.all(BazaarRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: BazaarFixedColors.slabLine)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 13),
                child: Text(
                  block.language,
                  style: TextStyle(
                    fontFamily: mono,
                    fontSize: BazaarType.mark.size,
                    color: BazaarFixedColors.slabOnSurfaceMuted,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 17),
                child: Text.rich(
                  key: const Key('code-body'),
                  TextSpan(
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: BazaarType.code.size,
                      height: BazaarType.code.height,
                      color: BazaarFixedColors.slabOnSurface,
                    ),
                    children: [
                      for (final (index, line) in block.lines.indexed) ...[
                        if (index > 0) const TextSpan(text: '\n'),
                        for (final token in line)
                          TextSpan(
                            text: token.text,
                            style: TextStyle(
                              color: BazaarSlab.forRole(token.role),
                              fontWeight: token.bold ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ],
                  ),
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

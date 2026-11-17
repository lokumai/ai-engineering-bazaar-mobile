import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A code block on the slab (`w3b` F.1): a head strip naming the language, then the lines in mono, coloured by each
/// token's role and bold only where the bundle marks it (A17), scrolling sideways instead of wrapping. The slab
/// tokens are the same in both themes, so the slab is the dark Night slab in both. The block is a container named
/// `{language} code`, or `Program output` for output. A code block's head has Copy at its end, which puts the code on
/// the clipboard and says Copied for a moment (plan 12.9); output has none.
class CodeBlockView extends StatelessWidget {
  const CodeBlockView({super.key, required this.block});

  final CodeBlock block;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mono = monoFamily(Theme.of(context).platform);
    final output = block.language == 'output';
    return Semantics(
      key: const Key('code-block'),
      container: true,
      explicitChildNodes: true,
      label: output ? s.block_program_output : s.block_code_label(block.language),
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
                padding: EdgeInsetsDirectional.only(start: 13, end: 4, top: output ? 9 : 0, bottom: output ? 9 : 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        block.language,
                        style: TextStyle(
                          fontFamily: mono,
                          fontSize: BazaarType.mark.size,
                          color: BazaarFixedColors.slabOnSurfaceMuted,
                        ),
                      ),
                    ),
                    if (!output) _CopyButton(text: codeText(block)),
                  ],
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

/// The plain text of [block], its lines joined by newlines, as Copy puts it on the clipboard.
String codeText(CodeBlock block) => [for (final line in block.lines) line.map((token) => token.text).join()].join('\n');

/// Copy on a code block's head (plan 12.9): puts [text] on the clipboard, then says Copied for a moment.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  /// How long Copied stays.
  static const _shown = Duration(seconds: 2);

  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(_shown, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      liveRegion: true,
      child: TextButton.icon(
        key: const Key('code-copy'),
        onPressed: _copy,
        style: TextButton.styleFrom(foregroundColor: BazaarFixedColors.slabOnSurfaceMuted),
        icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
        label: Text(_copied ? s.block_code_copied : s.block_code_copy),
      ),
    );
  }
}

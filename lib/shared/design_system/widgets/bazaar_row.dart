import 'package:flutter/material.dart';

import '../bazaar_tokens.g.dart';

/// A row straight on the page's ground, with no box around it: rows in a list stand apart by a hairline between them
/// ([BazaarRows]), not each in a card of its own (the user, 2026-11-10: fewer boxes).
///
/// With [onTap], the whole row is one button: [semanticLabel] then names it, or its texts do when null.
class BazaarRow extends StatelessWidget {
  const BazaarRow({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    if (onTap == null) return content;
    final row = InkWell(borderRadius: const BorderRadius.all(BazaarRadii.md), onTap: onTap, child: content);
    if (semanticLabel case final label?) {
      return Semantics(container: true, button: true, label: label, onTap: onTap, excludeSemantics: true, child: row);
    }
    return MergeSemantics(child: Semantics(button: true, child: row));
  }
}

/// [children] one under the other with a hairline between each two.
class BazaarRows extends StatelessWidget {
  const BazaarRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[if (i > 0) const Divider(height: 1, thickness: 0.5), child],
      ],
    );
  }
}

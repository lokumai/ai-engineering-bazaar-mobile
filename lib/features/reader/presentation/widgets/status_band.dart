import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';

/// The separator between the band's two words; the screen reader skips it, as the web hides it.
const _separator = ' · ';

/// The band over a planned module (web `StatusBand.tsx:13-20`, `app/derived.css:74-81`): `Planned`, then
/// `Schedule of parts only`, or `Partly written` when the draft has written sections.
class StatusBand extends StatelessWidget {
  const StatusBand({super.key, required this.partlyWritten});

  final bool partlyWritten;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final planned = s.module_planned;
    final band = partlyWritten ? s.reader_band_partly_written : s.reader_band_parts_only;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: const Border(left: BorderSide(width: 2, color: BazaarFixedColors.caution)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: planned,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: _separator),
            TextSpan(text: band),
          ],
        ),
        semanticsLabel: '$planned $band',
        style: TextStyle(fontSize: BazaarType.item.size, height: BazaarType.item.height, color: colors.onSurface),
      ),
    );
  }
}

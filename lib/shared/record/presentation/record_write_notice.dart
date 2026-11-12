import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The line that says the latest record write did not reach the device (spec 3.3.9), shown under the completion row
/// and on the progress page; nothing while the record is saved or a write runs.
///
/// The whole line is one tap target that leads to the backup, so the sentence stays one translatable string. Its text
/// is on-surface and the fault colour marks only its edge (Decision A18). It is a live region, as the web's line is an
/// alert.
class RecordWriteNotice extends StatelessWidget {
  const RecordWriteNotice({super.key, required this.writeState, required this.onBackUp});

  final WriteState writeState;
  final VoidCallback onBackUp;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final reason = switch (writeState) {
      WriteSaved() || WritePending() => null,
      WriteQuota() => s.record_not_saved_quota,
      WriteBlocked() => s.record_not_saved_blocked,
      WriteTooLarge() => s.record_not_saved_too_large,
    };
    if (reason == null) return const SizedBox.shrink();
    final colors = context.bazaarColors;
    return Semantics(
      key: const Key('write-failure'),
      liveRegion: true,
      button: true,
      child: InkWell(
        onTap: onBackUp,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTapTarget(defaultTargetPlatform)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(width: 2, color: colors.fault)),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Text(
                  s.record_not_saved(reason),
                  style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

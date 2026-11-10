import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/presentation/record_write_notice.dart';
import 'package:ai_engineering_bazaar/shared/utils/short_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The completion control of a written module (web `SignOff.tsx`, `app/completion.css:87-139`): one checkbox row that
/// reads the record of [doc]'s track, with the day it was completed, and under it the write-failure line. Nothing while
/// the record loads.
class CompletionRow extends StatelessWidget {
  const CompletionRow({super.key, required this.doc, required this.onToggle});

  final ModuleDoc doc;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordBloc, RecordState>(
      builder: (context, state) => switch (state) {
        RecordLoading() => const SizedBox.shrink(),
        RecordReady(:final record, :final writeState) => _row(
          context,
          record.signedOff(doc.key, doc.track),
          writeState,
        ),
      },
    );
  }

  Widget _row(BuildContext context, String? signedOff, WriteState writeState) {
    final s = S.of(context);
    final colors = context.bazaarColors;
    final done = signedOff != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: s.reader_completion_region,
          // The whole row is the control, as the web's row is the checkbox's label.
          child: CheckboxListTile(
            key: const Key('reader-completion'),
            value: done,
            onChanged: (_) => onToggle(),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: BazaarFixedColors.success,
            checkColor: BazaarFixedColors.onBar,
            tileColor: colors.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: done ? BazaarFixedColors.success : colors.lineStrong),
              borderRadius: const BorderRadius.all(BazaarRadii.xl),
            ),
            title: Text(
              s.reader_mark_complete,
              style: TextStyle(fontSize: BazaarType.body.size, color: colors.onSurface),
            ),
            subtitle: done
                ? Text(
                    s.reader_completed_on(shortDate(signedOff)),
                    style: TextStyle(fontSize: BazaarType.meta.size, color: colors.onSurfaceMuted),
                  )
                : null,
          ),
        ),
        RecordWriteNotice(writeState: writeState, onBackUp: () => unawaited(context.push<void>(BazaarPaths.settings))),
      ],
    );
  }
}

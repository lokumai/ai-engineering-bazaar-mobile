import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A line on Home while this launch set the stored progress aside: Home, the catalog and the reader then show none, and
/// the reason was only on Settings (review 11, record 5). A tap goes there; nothing is drawn otherwise.
class HomeRecordPointer extends StatelessWidget {
  const HomeRecordPointer({super.key});

  @override
  Widget build(BuildContext context) {
    final setAside = context.select<RecordBloc, bool>(
      (bloc) => switch (bloc.state) {
        RecordReady(:final quarantine) => quarantine != null,
        RecordLoading() => false,
      },
    );
    if (!setAside) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        key: const ValueKey('home-record-pointer'),
        onTap: () => context.go(BazaarPaths.settings),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(width: 2, color: context.bazaarColors.lineStrong)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, top: 4, bottom: 4),
            child: Text(
              S.of(context).home_record_set_aside,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

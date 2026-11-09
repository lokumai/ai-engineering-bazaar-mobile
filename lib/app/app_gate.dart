import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _log = AppLogger.getLogger('AppGate');

/// Shows [child], the router, only once the content and the record are both ready (spec 3.7); a loading page until
/// then, and a full-page notice when the bundled content cannot be opened.
class AppGate extends StatelessWidget {
  const AppGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch ((context.watch<ContentBloc>().state, context.watch<RecordBloc>().state)) {
      (ContentBroken(:final code), _) => _BrokenView(code: code),
      (ContentReady(), RecordReady()) => child,
      _ => const _LoadingView(),
    };
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator(semanticsLabel: S.of(context).loading)),
    );
  }
}

class _BrokenView extends StatelessWidget {
  const _BrokenView({required this.code});

  final ContentErrorCode code;

  @override
  Widget build(BuildContext context) {
    // The code goes to the log; the reader sees what happened, what restores it, and that the progress is kept.
    _log.warn('Content broken: {}', [code]);
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(l10n.content_broken_title, style: textTheme.headlineSmall)),
              const SizedBox(height: AppSpacing.md),
              Text(switch (code) {
                // The bundled content is intact; the store beside it could not be used.
                ContentErrorCode.storage => l10n.content_broken_storage_message,
                _ => l10n.content_broken_message,
              }, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

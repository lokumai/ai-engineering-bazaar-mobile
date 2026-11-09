import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Settings page (spec 3.6.1 row `settings`, Decision A8): the content notice, the content status with Check for
/// updates (spec 3.4.2 to 3.4.4), the licences, and the developer console when [openDevConsole] is set.
///
/// The data flows live on the progress page (A8). Only [ContentReady] draws; the other content states never mount,
/// since the app gate mounts the router only once the content is ready.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.openDevConsole});

  /// Opens the developer console (Decision A6); the router passes it in debug builds only, since a feature imports
  /// nothing from `app/`. Null hides the entry.
  final void Function(BuildContext context)? openDevConsole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (context.watch<ContentBloc>().state) {
        ContentReady ready => _SettingsView(ready: ready, openDevConsole: openDevConsole),
        ContentLoading() || ContentBroken() => const SizedBox.shrink(),
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.ready, required this.openDevConsole});

  final ContentReady ready;
  final void Function(BuildContext context)? openDevConsole;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final index = ready.index;
    final openDevConsole = this.openDevConsole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(s.settings, style: theme.textTheme.headlineSmall)),
          const SizedBox(height: AppSpacing.lg),
          if (ready.notice != null) ...[
            ContentNoticeBanner(notice: ready.notice),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SectionTitle(s.settings_content),
          _Fact(label: s.settings_content_version, value: index.contentVersion.substring(0, 12)),
          _Fact(label: s.settings_published, value: _utcDay(index.publishedAtInstant)),
          _Fact(
            label: s.settings_source,
            value: switch (ready.origin) {
              ContentOrigin.bundled => s.settings_source_bundled,
              ContentOrigin.downloaded => s.settings_source_downloaded,
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_refreshLine(s, ready.refresh), style: theme.textTheme.bodyMedium),
          _Action(
            label: s.settings_check_for_updates,
            onPressed: switch (ready.refresh) {
              RefreshChecking() => null,
              RefreshIdle() ||
              RefreshUpToDate() ||
              RefreshUpdated() ||
              RefreshFailed() ||
              RefreshNeedsAppUpdate() => () => context.read<ContentBloc>().add(const ContentRefreshRequested()),
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(s.settings_about),
          _Action(
            label: s.settings_licences,
            onPressed: () => showLicensePage(context: context, applicationName: s.app_title),
          ),
          if (openDevConsole != null) _Action(label: s.settings_dev_console, onPressed: () => openDevConsole(context)),
        ],
      ),
    );
  }

  /// The UTC day of [instant] as `YYYY-MM-DD`, whatever the device's zone.
  static String _utcDay(DateTime instant) => instant.toUtc().toIso8601String().substring(0, 10);

  static String _refreshLine(S s, RefreshStatus refresh) => switch (refresh) {
    RefreshIdle() => s.settings_refresh_idle,
    RefreshChecking() => s.settings_refresh_checking,
    RefreshUpToDate() => s.settings_refresh_up_to_date,
    RefreshUpdated() => s.settings_refresh_updated,
    RefreshNeedsAppUpdate() => s.settings_refresh_needs_app_update,
    RefreshFailed(:final code) => s.settings_refresh_failed(_reason(s, code)),
  };

  static String _reason(S s, ContentErrorCode code) => switch (code) {
    ContentErrorCode.network => s.settings_refresh_reason_network,
    ContentErrorCode.httpStatus => s.settings_refresh_reason_http_status,
    ContentErrorCode.format => s.settings_refresh_reason_format,
    ContentErrorCode.checksum => s.settings_refresh_reason_checksum,
    ContentErrorCode.storage => s.settings_refresh_reason_storage,
    ContentErrorCode.bundledIndexUnreadable ||
    ContentErrorCode.missing ||
    ContentErrorCode.corrupt => s.settings_refresh_reason_stored,
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
    );
  }
}

/// One labelled value of the content status, read as one node.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Wrap(
          spacing: AppSpacing.md,
          children: [
            Text(label, style: textTheme.bodyMedium?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
            Text(value, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// A start-aligned text button; the theme sizes it to the platform's tap target.
class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

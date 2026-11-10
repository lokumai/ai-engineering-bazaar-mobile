import 'package:ai_engineering_bazaar/features/settings/presentation/widgets/data_section.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_notice_banner.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_cubit.dart';
import 'package:ai_engineering_bazaar/shared/track/track_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Settings page (spec 3.6.1 row `settings`, Decision A8): the content notice, the track the reader chose (plan 1L,
/// the one place it changes after Welcome), the reader's data with Back up, Restore and Reset (plan 1AB: the progress
/// page that held them is gone), the content status with Check for updates (spec 3.4.2 to 3.4.4), the licences, and
/// the developer console when [openDevConsole] is set.
///
/// The redesign draws each section as a card under a section rule, with the same content (plan Phase 1H). Only
/// [ContentReady] draws; the other content states never mount, since the app gate mounts the router only once the
/// content is ready.
/// The key of [language]'s segment in the language setting.
Key settingsLanguageKey(String language) => ValueKey('settings-language-$language');

/// The key of [track]'s segment in the track setting.
Key settingsTrackKey(Track track) => ValueKey('settings-track-${track.id}');

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
          SectionRule(title: s.settings_reading),
          const SizedBox(height: AppSpacing.md),
          BazaarCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Text(s.settings_track, style: theme.textTheme.titleSmall),
                BazaarSegmentedControl<Track>(
                  semanticLabel: s.settings_track,
                  selected: context.watch<TrackCubit>().state,
                  onSelected: (track) => context.read<TrackCubit>().choose(track),
                  segments: [
                    for (final info in index.tracks)
                      BazaarSegment(
                        value: info.track,
                        label: trackName(s, info.track),
                        key: settingsTrackKey(info.track),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(s.settings_language, style: theme.textTheme.titleSmall),
                BazaarSegmentedControl<String>(
                  semanticLabel: s.settings_language,
                  selected: context.watch<LanguageCubit>().state,
                  onSelected: (language) => context.read<LanguageCubit>().choose(language),
                  segments: [
                    for (final language in LanguageCubit.supported)
                      BazaarSegment(
                        value: language,
                        label: LanguageCubit.names[language]!,
                        key: settingsLanguageKey(language),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionRule(title: s.settings_data),
          const SizedBox(height: AppSpacing.md),
          const DataSection(),
          const SizedBox(height: AppSpacing.xl),
          SectionRule(title: s.settings_content),
          const SizedBox(height: AppSpacing.md),
          BazaarCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionRule(title: s.settings_about),
          const SizedBox(height: AppSpacing.md),
          BazaarCard(
            shape: BazaarCardShape.leaf,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Action(
                  label: s.settings_licences,
                  onPressed: () => showLicensePage(context: context, applicationName: s.app_title),
                ),
                if (openDevConsole != null)
                  _Action(label: s.settings_dev_console, onPressed: () => openDevConsole(context)),
              ],
            ),
          ),
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

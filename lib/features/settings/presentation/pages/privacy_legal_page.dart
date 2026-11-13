import 'package:ai_engineering_bazaar/features/settings/domain/site_owner.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/utils/external_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Settings' privacy and legal notes (plan 3.4, web D122): what the app does with data, the owner as the registry has
/// it, and the note on third-party marks and images. The privacy note is the app's own, since the app is not the site:
/// it downloads the course from the site and, when [crashReports] is set, sends crash reports. It ends on the site's note,
/// which covers the app too (web D138).
class PrivacyLegalPage extends StatelessWidget {
  const PrivacyLegalPage({super.key, required this.crashReports});

  /// Whether this build sends crash reports (a Sentry DSN is set); the note says so only then.
  final bool crashReports;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.privacy_title),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                _Paragraph(s.privacy_no_data),
                _Paragraph(s.privacy_on_device),
                _Paragraph(s.privacy_download),
                _Link(label: s.privacy_github_pages, uri: LegalLinks.githubPages),
                _Link(label: s.privacy_github_statement, uri: LegalLinks.githubPrivacy),
                if (crashReports) _Paragraph(s.privacy_crash),
                _Paragraph(s.privacy_contact),
                _Link(label: SiteOwner.email, uri: LegalLinks.email),
                _Link(label: s.privacy_site_note, uri: context.read<WebLinks>().privacy),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionRule(title: s.legal_title),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(label: s.legal_owner, value: SiteOwner.tradeName),
                _Row(label: s.legal_mersis, value: SiteOwner.mersis),
                _Row(label: s.legal_address, value: SiteOwner.address),
                _Row(label: s.legal_email, value: SiteOwner.email, uri: LegalLinks.email),
                _Row(label: s.legal_phone, value: SiteOwner.phone, uri: LegalLinks.phone),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  s.legal_marks_title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.bazaarColors.onSurfaceTitle),
                ),
                _Paragraph(s.legal_marks),
                _Paragraph(s.legal_images),
                _Link(label: SiteOwner.email, uri: LegalLinks.email),
                _Paragraph(s.legal_licence),
                _Link(label: s.legal_licence_link, uri: LegalLinks.licence),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodyMedium);
}

/// A link that opens outside the app, its text flush with the paragraphs; the theme sizes it to the platform's tap
/// target.
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(style: _flush, onPressed: () => openExternalLink(context, uri), child: Text(label)),
    );
  }
}

/// A text button with no inset, so its text lines up with the text around it.
final _flush = TextButton.styleFrom(padding: EdgeInsets.zero, alignment: AlignmentDirectional.centerStart);

/// One fact of the owner: its label over its value, read as one node, the value a link when [uri] is given.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.uri});

  final String label;
  final String value;
  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final uri = this.uri;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.bodySmall?.copyWith(color: context.bazaarColors.onSurfaceMuted)),
            if (uri == null)
              Text(value, style: textTheme.bodyMedium)
            else
              TextButton(style: _flush, onPressed: () => openExternalLink(context, uri), child: Text(value)),
          ],
        ),
      ),
    );
  }
}

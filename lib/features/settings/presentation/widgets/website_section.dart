import 'package:ai_engineering_bazaar/features/settings/application/code_scan_cubit.dart';
import 'package:ai_engineering_bazaar/features/settings/application/website_link_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:ai_engineering_bazaar/shared/design_system/share_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Settings' The website section (plan 17.1, 17.5; the owner, 2026-11-19): how progress moves between the website and
/// this phone, the website first. From the website to this phone says where the website's code is (Progress, Move to
/// the app) and scans it in the app where the phone can; from this phone to the website shares a transfer link to open
/// on the computer.
class WebsiteSection extends StatelessWidget {
  const WebsiteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.read<WebLinks>().site;
    return MultiBlocProvider(
      providers: [
        BlocProvider<CodeScanCubit>(
          create: (context) => CodeScanCubit(scanner: context.read<ICodeScanner>(), site: site)..load(),
        ),
        BlocProvider<WebsiteLinkCubit>(
          create: (context) => WebsiteLinkCubit(
            recordBloc: context.read<RecordBloc>(),
            packer: context.read<ITransferPacker>(),
            shareSheet: context.read<IShareSheet>(),
            site: site,
          ),
        ),
      ],
      child: const _WebsiteSectionView(),
    );
  }
}

class _WebsiteSectionView extends StatelessWidget {
  const _WebsiteSectionView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scan = context.watch<CodeScanCubit>().state;
    final send = context.watch<WebsiteLinkCubit>().state;
    final scanLine = switch (scan.status) {
      CodeScanStatus.notALink => s.website_scan_not_a_link,
      CodeScanStatus.denied => s.website_scan_denied,
      CodeScanStatus.failed => s.website_scan_failed,
      // Google's scanner may first be fetched by Play services, a wait with the button off and no word (review 3,
      // finding 8).
      CodeScanStatus.scanning => s.website_scan_opening,
      CodeScanStatus.idle || CodeScanStatus.found => null,
    };
    final sendLine = switch (send) {
      WebsiteLinkState.empty => s.data_send_empty,
      WebsiteLinkState.failed => s.data_send_failed,
      WebsiteLinkState.tooLarge => s.data_send_too_large,
      WebsiteLinkState.idle || WebsiteLinkState.sending => null,
    };
    return BlocListener<CodeScanCubit, CodeScanState>(
      listenWhen: (previous, current) => current.status == CodeScanStatus.found && current.payload != null,
      listener: (context, state) {
        context.read<CodeScanCubit>().opened();
        context.push(BazaarPaths.transfer, extra: state.payload);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          _Way(
            title: s.website_from_title,
            text: s.website_from_text,
            action: scan.available
                ? OutlinedButton.icon(
                    key: const ValueKey('settings-scan-code'),
                    onPressed: scan.status == CodeScanStatus.scanning
                        ? null
                        : () => context.read<CodeScanCubit>().scan(
                            s.website_scan_title,
                            cancel: MaterialLocalizations.of(context).cancelButtonLabel,
                          ),
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: Text(s.website_scan),
                  )
                : null,
            line: scanLine,
          ),
          _Way(
            title: s.website_to_title,
            text: s.website_to_text,
            action: OutlinedButton.icon(
              key: const ValueKey('settings-send-to-website'),
              onPressed: send == WebsiteLinkState.sending ? null : () => context.read<WebsiteLinkCubit>().send(),
              icon: Icon(shareIcon(context)),
              label: Text(s.data_send_to_website),
            ),
            line: sendLine,
          ),
        ],
      ),
    );
  }
}

/// One way progress moves: its name, what to do, its button and the line a press leaves.
class _Way extends StatelessWidget {
  const _Way({required this.title, required this.text, required this.action, required this.line});

  final String title;
  final String text;
  final Widget? action;
  final String? line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Semantics(header: true, child: Text(title, style: theme.textTheme.titleSmall)),
        Text(text, style: theme.textTheme.bodyMedium),
        ?action,
        if (line != null) Semantics(liveRegion: true, child: Text(line!, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

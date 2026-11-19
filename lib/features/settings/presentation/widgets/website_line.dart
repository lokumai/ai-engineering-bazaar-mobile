import 'package:ai_engineering_bazaar/features/settings/application/website_link_cubit.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The website, under the data line (plan 17.1): how progress moves between this phone and the website, and Send to
/// the website, which shares a transfer link. The other way is the website's: its Progress page shows a code that the
/// phone's camera opens in the app.
class WebsiteLine extends StatelessWidget {
  const WebsiteLine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WebsiteLinkCubit>(
      create: (context) => WebsiteLinkCubit(
        recordBloc: context.read<RecordBloc>(),
        packer: context.read<ITransferPacker>(),
        shareSheet: context.read<IShareSheet>(),
        site: context.read<WebLinks>().site,
      ),
      child: const _WebsiteLineView(),
    );
  }
}

class _WebsiteLineView extends StatelessWidget {
  const _WebsiteLineView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final state = context.watch<WebsiteLinkCubit>().state;
    final line = switch (state) {
      WebsiteLinkState.empty => s.data_send_empty,
      WebsiteLinkState.failed => s.data_send_failed,
      WebsiteLinkState.idle || WebsiteLinkState.sending => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Semantics(header: true, child: Text(s.data_website_title, style: theme.textTheme.titleSmall)),
        Text(s.data_website_text, style: theme.textTheme.bodyMedium),
        OutlinedButton.icon(
          key: const ValueKey('settings-send-to-website'),
          onPressed: state == WebsiteLinkState.sending ? null : () => context.read<WebsiteLinkCubit>().send(),
          icon: const Icon(Icons.ios_share_outlined),
          label: Text(s.data_send_to_website),
        ),
        if (line != null) Semantics(liveRegion: true, child: Text(line, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

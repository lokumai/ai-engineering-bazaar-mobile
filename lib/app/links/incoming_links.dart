import 'dart:async';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Opens the site's links the phone hands the app (plan 17.2): a module, a level or a catalog goes to its page, and a
/// progress transfer opens the transfer page over the shell (plan 17.1). A link the app has no page for is left alone.
///
/// It stands under Welcome, so a link the app was opened with on a first launch waits on the native side until Welcome
/// is done, and is opened then.
class IncomingLinks extends StatefulWidget {
  const IncomingLinks({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<IncomingLinks> createState() => _IncomingLinksState();
}

class _IncomingLinksState extends State<IncomingLinks> {
  static final _log = AppLogger.getLogger('IncomingLinks');

  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    final source = context.read<ILinkSource>();
    _subscription = source.links.listen(_open);
    unawaited(source.takeWaiting().then((links) => links.forEach(_open)));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _open(Uri uri) {
    if (!mounted) return;
    final link = SiteLink.parse(uri, context.read<WebLinks>().site);
    // The kind only: a transfer's link carries the reader's progress.
    _log.info('link opened: {}', [link?.runtimeType]);
    switch (link) {
      case SiteCatalog(:final track):
        widget.router.go(BazaarPaths.catalog(track));
      case SiteLevel(:final track, :final level):
        widget.router.go(BazaarPaths.level(track, level));
      case SiteModule(:final track, :final moduleKey):
        widget.router.go(BazaarPaths.module(track, moduleKey));
      case SiteTransfer(:final payload):
        unawaited(widget.router.push(BazaarPaths.transfer, extra: payload));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

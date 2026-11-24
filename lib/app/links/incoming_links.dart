import 'dart:async';

import 'package:ai_engineering_bazaar/core/logging/app_logger.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/navigation/web_links.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Opens the site's links the phone hands the app (plan 17.2): a catalog goes to its page, a module or a level opens over
/// its track's catalog, and a progress transfer opens the transfer page over the shell (plan 17.1). A link the app has
/// no page for is left alone.
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
    if (link != null) _closeAbovePages();
    switch (link) {
      case SiteCatalog(:final track):
        widget.router.go(BazaarPaths.catalog(track));
      case SiteLevel(:final track, :final level):
        _openOverCatalog(BazaarPaths.catalog(track), BazaarPaths.level(track, level));
      case SiteModule(:final track, :final moduleKey):
        _openOverCatalog(BazaarPaths.catalog(track), BazaarPaths.module(track, moduleKey));
      case SiteTransfer(:final payload):
        unawaited(widget.router.push(BazaarPaths.transfer, extra: payload));
      case null:
        break;
    }
  }

  /// Opens [page] over [catalog], as a tap in the catalog does: with a back arrow and an edge swipe back to it. Gone to
  /// alone, it was the shell's only page, with no way back but a tab (review 11, features 4).
  void _openOverCatalog(String catalog, String page) {
    widget.router.go(catalog);
    unawaited(widget.router.push(page));
  }

  /// Closes the dialogs and the full-screen quiz above the pages, which the link would leave standing over a page
  /// that is gone, their buttons dead on its closed bloc (review 4, finding 10; review 5, finding 16).
  void _closeAbovePages() {
    widget.router.routerDelegate.navigatorKey.currentState?.popUntil((route) => route.settings is Page<Object?>);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

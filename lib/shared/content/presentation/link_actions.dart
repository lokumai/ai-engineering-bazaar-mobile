import 'dart:async';

import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/navigation/bazaar_paths.dart';
import 'package:ai_engineering_bazaar/shared/utils/external_link.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Follows a link of the content.
///
/// A module link pushes the module in its track, with its fragment (a heading id or null) as the route's `extra`; the
/// link's language is not used in v1 (spec 3.6.2). An anchor scrolls within the page through [scrollTo]. A catalog link
/// pushes the For Engineers catalog root, as the web's `/sheets/` does from both tracks (Decision A39), so back returns
/// to the page the link was on (plan 1M). An external
/// link opens outside the app. An unknown target is never tappable (the renderer draws it as plain text), so following
/// one throws.
void followLink(BuildContext context, LinkTarget target, {required void Function(String id) scrollTo}) {
  switch (target) {
    case ModuleTarget(:final key, :final track, :final fragment):
      unawaited(context.push<void>(BazaarPaths.module(track, key), extra: fragment));
    case AnchorTarget(:final id):
      scrollTo(id);
    case CatalogTarget():
      unawaited(context.push<void>(BazaarPaths.catalogEngineers));
    case ExternalTarget(:final url):
      unawaited(openExternalLink(context, Uri.parse(url)));
    case UnknownTarget(:final kind):
      throw StateError('An unknown link target is not openable: $kind');
  }
}

import 'dart:async';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/block_list.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/link_actions.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:ai_engineering_bazaar/shared/design_system/reduced_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The level page's `General notes` (web `LevelCatalog`, item 4): the heading and the level document at [readme].
///
/// The catalog keeps no bloc of its own (spec 3.6.1); this widget only reads a document to draw. A level document has
/// no web page, so an unknown block shows no `Open on the web` (A23). A document missing, corrupt or malformed on the
/// device shows [ContentUnreadable] under the heading; any other error is rethrown from `build`: it is a fault, not a
/// state of the content.
class LevelNotes extends StatefulWidget {
  const LevelNotes({super.key, required this.readme, required this.diagramThemes});

  /// The site path of the level document (`LevelEntry.readme`).
  final String readme;
  final DiagramThemes diagramThemes;

  @override
  State<LevelNotes> createState() => _LevelNotesState();
}

sealed class _Read {
  const _Read();
}

final class _Reading extends _Read {
  const _Reading();
}

final class _Arrived extends _Read {
  const _Arrived(this.doc);
  final LevelDoc doc;
}

final class _Unreadable extends _Read {
  const _Unreadable();
}

final class _Failed extends _Read {
  const _Failed(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

class _LevelNotesState extends State<LevelNotes> {
  _Read _read = const _Reading();

  /// The path of the read in flight or done; a result for another path is dropped.
  String? _readPath;

  /// The key of each heading of the document, by heading id.
  final _headingKeys = <String, GlobalKey>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readPath == null) _start();
  }

  @override
  void didUpdateWidget(LevelNotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readme != widget.readme) _start();
  }

  void _start() {
    final path = widget.readme;
    _readPath = path;
    _read = const _Reading();
    _headingKeys.clear();
    final repository = context.read<IContentRepository>();
    // Future.sync: an error thrown before the read returns a future lands in the same branch as a failed read.
    Future.sync(() => repository.readLevelDoc(path)).then(
      (doc) => _settle(path, _Arrived(doc)),
      onError: (Object error, StackTrace stackTrace) => _settle(
        path,
        error is ContentMissingException || error is ContentCorruptException || error is ContentFormatException
            ? const _Unreadable()
            : _Failed(error, stackTrace),
      ),
    );
  }

  void _settle(String path, _Read read) {
    if (!mounted || path != _readPath) return;
    setState(() => _read = read);
  }

  GlobalKey _headingKey(String id) => _headingKeys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls the heading [id] of the document into view, at once under reduced motion (spec 3.10).
  void _scrollTo(String id) {
    final target = _headingKeys[id]?.currentContext;
    if (target == null) throw StateError('No heading of this level document has the id $id');
    unawaited(Scrollable.ensureVisible(target, duration: motionDuration(context, BazaarMotion.shift)));
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_read) {
      _Reading() => const SizedBox.shrink(),
      _Arrived(:final doc) => BlockList(
        blocks: doc.blocks,
        render: BlockRenderContext(
          onLink: (target) => followLink(context, target, scrollTo: _scrollTo),
          webPage: null,
          headingKey: _headingKey,
          diagramThemes: widget.diagramThemes,
        ),
      ),
      _Unreadable() => const ContentUnreadable(),
      _Failed(:final error, :final stackTrace) => Error.throwWithStackTrace(error, stackTrace),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 44),
        Semantics(
          container: true,
          header: true,
          child: Text(
            S.of(context).level_general_notes,
            style: TextStyle(
              fontSize: BazaarType.section.size,
              height: BazaarType.section.height,
              fontWeight: FontWeight.w600,
              letterSpacing: BazaarType.trackingSection * BazaarType.section.size,
              color: context.bazaarColors.onSurfaceTitle,
            ),
          ),
        ),
        const SizedBox(height: 14),
        body,
      ],
    );
  }
}

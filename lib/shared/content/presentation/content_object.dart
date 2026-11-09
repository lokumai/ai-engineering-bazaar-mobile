import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the content object at [sitePath] from the [IContentRepository] in context (spec 3.4.7) and builds it.
///
/// It shows [placeholder] while the read runs, [builder] with the bytes once they arrive, and [unreadable] when the
/// object is missing or corrupt on the device. Any other error is rethrown from `build`: it is a fault, not a state of
/// the content.
class ContentObjectBuilder extends StatefulWidget {
  const ContentObjectBuilder({
    super.key,
    required this.sitePath,
    required this.builder,
    required this.unreadable,
    this.placeholder = const SizedBox.shrink(),
  });

  final String sitePath;
  final Widget Function(BuildContext context, Uint8List bytes) builder;
  final Widget Function(BuildContext context) unreadable;
  final Widget placeholder;

  @override
  State<ContentObjectBuilder> createState() => _ContentObjectBuilderState();
}

sealed class _Read {
  const _Read();
}

final class _Reading extends _Read {
  const _Reading();
}

final class _Arrived extends _Read {
  const _Arrived(this.bytes);
  final Uint8List bytes;
}

final class _Unreadable extends _Read {
  const _Unreadable();
}

final class _Failed extends _Read {
  const _Failed(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

class _ContentObjectBuilderState extends State<ContentObjectBuilder> {
  _Read _read = const _Reading();

  /// The path of the read in flight or done; a result for another path is dropped.
  String? _readPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readPath == null) _start();
  }

  @override
  void didUpdateWidget(ContentObjectBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sitePath != widget.sitePath) _start();
  }

  void _start() {
    final path = widget.sitePath;
    _readPath = path;
    _read = const _Reading();
    final repository = context.read<IContentRepository>();
    // Future.sync: an error thrown before the read returns a future lands in the same branch as a failed read.
    Future.sync(() => repository.readObject(path)).then(
      (bytes) => _settle(path, _Arrived(bytes)),
      onError: (Object error, StackTrace stackTrace) => _settle(
        path,
        error is ContentMissingException || error is ContentCorruptException
            ? const _Unreadable()
            : _Failed(error, stackTrace),
      ),
    );
  }

  void _settle(String path, _Read read) {
    if (!mounted || path != _readPath) return;
    setState(() => _read = read);
  }

  @override
  Widget build(BuildContext context) => switch (_read) {
    _Reading() => widget.placeholder,
    _Arrived(:final bytes) => widget.builder(context, bytes),
    _Unreadable() => widget.unreadable(context),
    _Failed(:final error, :final stackTrace) => Error.throwWithStackTrace(error, stackTrace),
  };
}

/// Says a part of the course could not be read on this device, under [alt] when it has one: the state of a content
/// object that is missing or corrupt (spec 3.4.7).
class ContentUnreadable extends StatelessWidget {
  const ContentUnreadable({super.key, this.alt});

  final String? alt;

  @override
  Widget build(BuildContext context) {
    final colors = context.bazaarColors;
    final alt = this.alt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: const BorderRadius.all(BazaarRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alt != null && alt.isNotEmpty) Text(alt, style: TextStyle(color: colors.onSurface)),
          Text(
            S.of(context).content_unreadable,
            style: TextStyle(color: colors.onSurfaceMuted, fontSize: BazaarType.meta.size),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the content object at [sitePath] from the [IContentRepository] in context (spec 3.4.7) and builds it.
///
/// It shows [placeholder] while the read runs, [builder] with the bytes once they arrive, and [unreadable] when the
/// object is missing or corrupt on the device. Any other error is a fault, not a state of the content: it is reported
/// through [FlutterError.reportError], as a throw from `build` would be, and [unreadable] stands in its place rather
/// than a grey box (review 8).
class ContentObjectBuilder extends StatefulWidget {
  const ContentObjectBuilder({
    super.key,
    required this.sitePath,
    required this.builder,
    required this.unreadable,
    this.placeholder = const SizedBox.shrink(),
    this.whenNear = false,
  });

  final String sitePath;
  final Widget Function(BuildContext context, Uint8List bytes) builder;
  final Widget Function(BuildContext context) unreadable;
  final Widget placeholder;

  /// Whether the read waits until the object is within a screen of the view of the page it scrolls in: a module's
  /// figures were all read and decoded as it opened, below the fold too (review 11, architecture 5). Only for a
  /// [placeholder] as large as what it stands for, so the page's length does not change when the read is done.
  final bool whenNear;

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
  const _Failed();
}

class _ContentObjectBuilderState extends State<ContentObjectBuilder> {
  _Read _read = const _Reading();

  /// The path of the read in flight or done; a result for another path is dropped.
  String? _readPath;

  /// The scroll watched while the read waits for the object to come near ([ContentObjectBuilder.whenNear]).
  ScrollPosition? _watched;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readPath != null) return;
    if (widget.whenNear) {
      _waitUntilNear();
    } else {
      _start();
    }
  }

  @override
  void didUpdateWidget(ContentObjectBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sitePath != widget.sitePath && _readPath != null) _start();
  }

  @override
  void dispose() {
    _unwatch();
    super.dispose();
  }

  /// Watches the page's scroll, and checks after this frame, until the object is near enough to read.
  void _waitUntilNear() {
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position == null) return _start();
    if (!identical(position, _watched)) {
      _unwatch();
      _watched = position..addListener(_checkNear);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNear());
  }

  void _unwatch() {
    _watched?.removeListener(_checkNear);
    _watched = null;
  }

  /// Starts the read once the object is within a screen of the view, above or below it.
  void _checkNear() {
    if (!mounted || _readPath != null) return;
    // A scroll can move while a frame is laid out; the check waits for the frame's end.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _checkNear());
      return;
    }
    final box = context.findRenderObject();
    final view = _watched?.context.notificationContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize || view is! RenderBox || !view.hasSize) return;
    final viewRect = view.localToGlobal(Offset.zero) & view.size;
    final near = viewRect.inflate(viewRect.longestSide);
    if (!near.overlaps(box.localToGlobal(Offset.zero) & box.size)) return;
    _unwatch();
    setState(_start);
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
            : _failed(error, stackTrace),
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
    _Failed() => widget.unreadable(context),
  };

  /// Reports the fault [error] and reads as failed.
  static _Read _failed(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'content',
        context: ErrorDescription('reading a content object'),
      ),
    );
    return const _Failed();
  }
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

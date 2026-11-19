import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/listen/presentation/listen_progress.dart';

/// The module read aloud, on a thin bar over the navigation while the reader is elsewhere in the app (the owner,
/// 2026-11-18): play or pause, its title, which opens it where the voice is, and a way to stop. On the page's ground
/// under a line of how far along.
class ListenBar extends StatelessWidget {
  const ListenBar({super.key, required this.state, required this.onOpen});

  final ListenOn state;

  /// Opens the module being read.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final listen = context.read<ListenCubit>();
    return ColoredBox(
      key: const ValueKey('listen-bar'),
      color: colors.surface,
      // Clear of the screen's foot while the navigation is folded away under a module read.
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenProgress(state: state),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('listen-bar-toggle'),
                    tooltip: state.playing ? s.listen_pause : s.listen_play,
                    onPressed: state.playing ? listen.pause : listen.resume,
                    color: colors.primary,
                    icon: Icon(state.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                    iconSize: 30,
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: s.listen_open(state.title),
                      excludeSemantics: true,
                      onTap: onOpen,
                      child: InkWell(
                        key: const ValueKey('listen-bar-open'),
                        onTap: onOpen,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            spacing: 6,
                            children: [
                              Icon(Icons.headphones_rounded, size: 16, color: colors.onSurfaceMuted),
                              Expanded(
                                child: Text(
                                  state.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceTitle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('listen-bar-stop'),
                    tooltip: s.listen_stop,
                    onPressed: listen.stop,
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/listen/application/listen_cubit.dart';
import 'package:ai_engineering_bazaar/shared/record/application/record_bloc.dart';

/// A module heard whole, every part read aloud to its end over one sitting or many, is marked completed as a module
/// read to its end is (the owner, 2026-11-18), with the same note and Undo, on whatever page the reader is. A module
/// already completed is left as it is.
class ListenCompletion extends StatelessWidget {
  const ListenCompletion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<ListenCubit, ListenState>(
    listenWhen: (before, now) => before is ListenOn && now is ListenIdle && now.heardAll != null,
    listener: (context, state) {
      final heard = (state as ListenIdle).heardAll!;
      final index = switch (context.read<ContentBloc>().state) {
        ContentReady(:final index) => index,
        _ => null,
      };
      final record = context.read<RecordBloc>();
      final completed = switch (record.state) {
        RecordReady(:final record) => record.signedOff(heard.module, heard.track) != null,
        RecordLoading() => true,
      };
      if (index == null || completed) return;
      final toggle = CompletionToggled(
        key: heard.module,
        track: heard.track,
        revision: index.module(heard.module)?.tracks[heard.track]?.revision?.hash,
      );
      record.add(toggle);
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('listen-completed'),
          content: Text(s.reader_auto_completed),
          action: SnackBarAction(label: s.data_undo, onPressed: () => record.add(toggle)),
        ),
      );
    },
    child: ListenNotStarted(child: child),
  );
}

/// A module the phone's voice started none of says so, on whatever page the reader is, where it was left kept (review
/// 2 finding 6, review 5 finding 11): before, the player closed without a word.
class ListenNotStarted extends StatelessWidget {
  const ListenNotStarted({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<ListenCubit, ListenState>(
    listenWhen: (before, now) => before is ListenOn && now is ListenIdle && now.notStarted != null,
    listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(key: const ValueKey('listen-not-started'), content: Text(S.of(context).listen_not_started)),
    ),
    child: child,
  );
}

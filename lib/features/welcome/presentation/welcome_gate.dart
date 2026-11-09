import 'package:ai_engineering_bazaar/features/welcome/application/welcome_bloc.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/features/welcome/presentation/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows [WelcomeView] in front of [child], the app, on the first launch only (plan Phase 1I); the app composes it
/// over the router, so Welcome has no route of its own and the web's routes stay the app's (A9).
///
/// While the store is asked, the page ground is shown, so neither screen flashes before the other.
class WelcomeGate extends StatelessWidget {
  const WelcomeGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WelcomeBloc(store: context.read<IWelcomeStore>())..add(const WelcomeStarted()),
      child: BlocBuilder<WelcomeBloc, WelcomeState>(
        builder: (context, state) => switch (state) {
          WelcomeChecking() => ColoredBox(color: Theme.of(context).colorScheme.surface),
          WelcomeShowing() => WelcomeView(onEnter: () => context.read<WelcomeBloc>().add(const WelcomeEntered())),
          WelcomeDone() => child,
        },
      ),
    );
  }
}

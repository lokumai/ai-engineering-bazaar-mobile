import 'package:ai_engineering_bazaar/features/settings/application/feedback_bloc.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Report a problem, from Settings (the owner, 2026-11-13): the reader writes what went wrong and sends it to Sentry
/// with the app's version and the device's model and system, its emails and secrets masked on the device. It asks no
/// name and no email. Shown only in a build that sends crash reports.
///
/// iOS has no back key to close the keyboard, so a tap outside the field or a drag of the page closes it, as in the
/// catalog's search; the field holds four to six lines and scrolls inside past them, so it fits above the keyboard
/// and the bottom navigation.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  /// The most a report holds; a longer text stops at it.
  static const int maxLength = 2000;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final state = context.watch<FeedbackBloc>().state;
    return Scaffold(
      // The shell's scaffold already makes room for the keyboard; this one making it again shrank the page by the
      // keyboard twice and cut the field in half.
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionRule(title: s.feedback_title),
            const SizedBox(height: AppSpacing.md),
            Text(s.feedback_intro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            switch (state) {
              FeedbackSent() => Semantics(
                liveRegion: true,
                child: Text(
                  s.feedback_sent,
                  style: theme.textTheme.bodyLarge?.copyWith(color: context.bazaarColors.onSurfaceTitle),
                ),
              ),
              FeedbackEditing() || FeedbackSending() || FeedbackFailed() => _Form(
                controller: _controller,
                sending: state is FeedbackSending,
                failed: state is FeedbackFailed,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.sending, required this.failed});

  final TextEditingController controller;
  final bool sending;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        TextField(
          controller: controller,
          enabled: !sending,
          minLines: 4,
          maxLines: 6,
          maxLength: FeedbackPage.maxLength,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(labelText: s.feedback_field, alignLabelWithHint: true),
        ),
        if (failed)
          Semantics(
            liveRegion: true,
            child: Text(s.feedback_failed, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => FilledButton(
              onPressed: sending || controller.text.trim().isEmpty
                  ? null
                  : () => context.read<FeedbackBloc>().add(FeedbackSubmitted(controller.text)),
              child: Text(sending ? s.feedback_sending : s.feedback_send),
            ),
          ),
        ),
      ],
    );
  }
}

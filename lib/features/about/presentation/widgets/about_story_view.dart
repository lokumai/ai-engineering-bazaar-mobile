import 'package:ai_engineering_bazaar/features/about/application/about_bloc.dart';
import 'package:ai_engineering_bazaar/features/about/presentation/about_art.dart';
import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/tokens/app_spacing.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The story of the Bazaar from the [AboutBloc] in context, as one scrolling page: the story's title, each section with
/// its picture, its heading and its paragraphs, then the motto; [footer] after it, as Welcome's way into the catalog.
///
/// The words are the bundle's (web D125) and the pictures the web's scenes in motion (`assets/about/SOURCE.md`): the
/// web plays its scenes under the scroll, and the app plays each one as a loop, like a short film (D111, the design
/// may differ). The story keeps
/// its own direction, and says it is in English when the app is not.
class AboutStoryView extends StatelessWidget {
  const AboutStoryView({super.key, required this.language, this.footer});

  /// The app's language, to say when the story is not written in it.
  final String language;

  /// Placed after the story, and alone when there is no story to show.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final state = context.watch<AboutBloc>().state;
    final List<Widget> children = switch (state) {
      AboutLoading() => [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator(semanticsLabel: s.loading)),
        ),
      ],
      AboutAbsent() => [],
      AboutFailed() => [Text(s.about_failed, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceMuted))],
      AboutReady(:final story) => [
        if (story.lang != language)
          Text(s.about_english, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted)),
        Directionality(
          textDirection: story.dir == TextDir.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: _Story(story: story),
        ),
      ],
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      children: [
        ...children,
        if (footer case final footer?) ...[const SizedBox(height: AppSpacing.xl), footer],
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.story});

  final StoryDoc story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.bazaarColors;
    final motto = story.motto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (story.title case final title?) ...[
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(color: colors.onSurfaceTitle),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        for (final (position, stall) in story.stalls.indexed) ...[
          if (position < AboutArt.scenes.length) ...[
            // Decoration: the heading and the paragraphs carry the section. Each picture is a short loop of the web's
            // scene in motion; under reduced motion `Image` holds it on its first frame.
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Image.asset(
                  AboutArt.scenes[position],
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Semantics(
            header: true,
            child: Text(stall.heading, style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurfaceTitle)),
          ),
          for (final paragraph in stall.paragraphs) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(paragraph, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
        if (motto != null)
          BazaarCard(
            child: MergeSemantics(
              child: Column(
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    motto.lead,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceMuted),
                  ),
                  for (final line in motto.lines)
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(color: colors.onSurfaceTitle),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

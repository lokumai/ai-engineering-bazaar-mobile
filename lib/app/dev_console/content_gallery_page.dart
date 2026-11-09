import 'package:ai_engineering_bazaar/shared/content/application/content_bloc.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/content_object.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/diagram_view.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/figure_image.dart';
import 'package:ai_engineering_bazaar/shared/content/presentation/logo_view.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_fonts.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/diagram_frame_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The debug-only gallery of the device spike (spec 3.6.4): every diagram an English document names, in both
/// variants; every logo under the light and the dark theme; every WebP figure; and the font samples of the platform.
///
/// It is reached at `/debug/gallery` in debug builds only, and its labels are paths and samples, not app copy.
class ContentGalleryPage extends StatelessWidget {
  const ContentGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final index = switch (context.watch<ContentBloc>().state) {
      ContentReady(:final index) => index,
      final state => throw StateError('The gallery needs ready content, not $state'),
    };
    return _Gallery(index: index);
  }
}

/// What the gallery draws, gathered from the documents.
final class _Items {
  const _Items({required this.unreadable, required this.diagrams, required this.figures});

  /// The paths of the documents that could not be read.
  final List<String> unreadable;

  /// Every distinct diagram, by `svgLight`.
  final List<DiagramBlock> diagrams;

  /// Every WebP figure, by `src`.
  final List<ImageBlock> figures;
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.index});

  final BundleIndex index;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  _Items? _items;
  (Object, StackTrace)? _failure;

  @override
  void initState() {
    super.initState();
    _gather(context.read<IContentRepository>(), widget.index).then(
      (items) {
        if (mounted) setState(() => _items = items);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) setState(() => _failure = (error, stackTrace));
      },
    );
  }

  static Future<_Items> _gather(IContentRepository repository, BundleIndex index) async {
    final unreadable = <String>[];
    final diagrams = <String, DiagramBlock>{};
    final figures = <String, ImageBlock>{};
    void walk(List<Block> blocks) {
      for (final block in blocks) {
        switch (block) {
          case DiagramBlock():
            diagrams.putIfAbsent(block.svgLight, () => block);
          case ImageBlock() when block.src.endsWith('.webp'):
            figures.putIfAbsent(block.src, () => block);
          case ListBlock(:final items):
            for (final item in items) {
              walk(item.blocks);
            }
          case QuoteBlock(:final blocks) || CalloutBlock(:final blocks):
            walk(blocks);
          default:
            break;
        }
      }
    }

    for (final entry in index.modules) {
      for (final track in Track.values) {
        final path = entry.tracks[track]?.docs['en'];
        if (path == null) continue;
        final ModuleDoc doc;
        try {
          doc = await repository.readModuleDoc(path);
        } on ContentMissingException {
          unreadable.add(path);
          continue;
        } on ContentCorruptException {
          unreadable.add(path);
          continue;
        } on ContentFormatException {
          unreadable.add(path);
          continue;
        }
        walk(doc.body ?? const []);
        walk(doc.draft?.written ?? const []);
      }
    }
    return _Items(unreadable: unreadable, diagrams: [...diagrams.values], figures: [...figures.values]);
  }

  @override
  Widget build(BuildContext context) {
    if (_failure case (final error, final stackTrace)) Error.throwWithStackTrace(error, stackTrace);
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());
    final platform = Theme.of(context).platform;
    final logos = [
      for (final path in widget.index.images.keys)
        if (path.contains('/logos/')) path,
    ];
    final themes = widget.index.diagramThemes;
    final rows = <Widget Function(BuildContext)>[
      for (final path in items.unreadable) (_) => ContentUnreadable(alt: path),
      for (final diagram in items.diagrams)
        for (final variant in DiagramVariant.values)
          (_) => _Labelled(
            label: diagram.svgLight,
            child: DiagramView(block: diagram, themes: themes, variant: variant),
          ),
      for (final path in logos) (_) => _LogoRow(path: path, platform: platform),
      for (final figure in items.figures)
        (_) => _Labelled(
          label: figure.src,
          child: FigureImage(block: figure),
        ),
      (_) => _Sample(family: sansFamily(platform), label: 'sans'),
      (_) => _Sample(family: monoFamily(platform), label: 'mono'),
      (_) => const _Sample(family: diagramFontFamily, label: 'Vazirmatn'),
      (_) => const _Sample(family: diagramFontFamily, label: 'Vazirmatn w700', weight: FontWeight.w700),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: 16), child: rows[i](context)),
    );
  }
}

/// A gallery item under its path.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      child,
    ],
  );
}

/// A logo under its path, drawn once under the light theme and once under the dark theme.
class _LogoRow extends StatelessWidget {
  const _LogoRow({required this.path, required this.platform});

  final String path;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) => _Labelled(
    label: path,
    child: Row(
      children: [
        for (final brightness in const [Brightness.light, Brightness.dark])
          Theme(
            data: bazaarTheme(brightness: brightness, platform: platform),
            child: Builder(
              builder: (context) => ColoredBox(
                color: context.bazaarColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LogoView(src: path, mono: path.endsWith('-mono.svg'), fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The font sample in [family] at [weight].
class _Sample extends StatelessWidget {
  const _Sample({required this.family, required this.label, this.weight = FontWeight.w400});

  final String? family;
  final String label;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => _Labelled(
    label: label,
    child: Text(
      'Sphinx of black quartz, judge my vow 0123456789',
      style: TextStyle(fontFamily: family, fontWeight: weight, fontSize: 18),
    ),
  );
}

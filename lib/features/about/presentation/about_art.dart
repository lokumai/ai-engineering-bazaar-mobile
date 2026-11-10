/// The pictures beside the story's sections (`assets/about/SOURCE.md`), by position as the web places its scenes: the
/// i-th picture stands by the i-th section, and a section past the last picture has none.
abstract final class AboutArt {
  static const scenes = [
    'assets/about/scene_1.webp',
    'assets/about/scene_2.webp',
    'assets/about/scene_3.webp',
    'assets/about/scene_4.webp',
    'assets/about/scene_5.webp',
  ];

  /// Each picture's width over its height: the treaty's hall is wider than the others' square.
  static const aspects = [710 / 560, 1.0, 1.0, 1.0, 1.0];
}

/// The pictures beside the story's sections (`assets/about/SOURCE.md`), by position as the web places its scenes: the
/// i-th picture stands by the i-th section, and a section past the last picture has none.
abstract final class AboutArt {
  /// Each scene in motion from its start, as the web starts it when its section arrives; it plays once and stays on
  /// its last frame.
  static const scenes = [
    'assets/about/scene_1.webp',
    'assets/about/scene_2.webp',
    'assets/about/scene_3.webp',
    'assets/about/scene_4.webp',
    'assets/about/scene_5.webp',
  ];

  /// Each scene's still picture, the web's own under reduced motion.
  static const stills = [
    'assets/about/scene_1_still.webp',
    'assets/about/scene_2_still.webp',
    'assets/about/scene_3_still.webp',
    'assets/about/scene_4_still.webp',
    'assets/about/scene_5_still.webp',
  ];

  /// Each picture's width over its height.
  static const aspects = [592 / 373, 537 / 529, 592 / 627, 541 / 528, 539 / 571];

  /// How many frames each scene's file holds, a run of equal frames being one longer frame: its section moves on only
  /// after the last, so the treaty gives its answer, the needle is bared, the seal pressed and the engraving drawn,
  /// whatever the device's pace.
  static const frames = [132, 150, 211, 200, 129];

  /// Whether the section at [position] waits for its scene to end: the memes have no end, so theirs does not.
  static bool waits(int position) => position < frames.length && position != 3;
}

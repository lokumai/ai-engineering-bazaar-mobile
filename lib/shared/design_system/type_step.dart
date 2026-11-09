/// A `--text-X` step of the web's type scale: [size] is its font size in logical pixels, and [height] is the
/// `--text-X--line-height` ratio, null when the web sets none.
final class TypeStep {
  const TypeStep({required this.size, this.height});

  final double size;
  final double? height;
}

import 'package:equatable/equatable.dart';

/// How large a module's text is drawn, as a factor on the phone's own text size (plan 12.5): a reader who set large
/// text on the phone keeps it, and this moves it a step either way.
enum ReadingSize {
  small(0.9),
  standard(1),
  large(1.15),
  larger(1.3),
  largest(1.45);

  const ReadingSize(this.factor);

  /// The factor on the phone's text size.
  final double factor;
}

/// How far apart the lines of a module's paragraphs stand (plan 12.5), as the line height of its body text.
enum ReadingSpacing {
  tight(1.45),
  comfortable(1.68),
  wide(1.95);

  const ReadingSpacing(this.lineHeight);

  /// The body text's line height, a multiple of its size; [comfortable] is the design's own.
  final double lineHeight;
}

/// The reader's reading settings (plan 12.5): the text size and the line spacing of a module's text. Kept on this
/// device apart from the record, which stays the web's.
final class ReadingStyle extends Equatable {
  const ReadingStyle({this.size = ReadingSize.standard, this.spacing = ReadingSpacing.comfortable});

  /// The design's own: the phone's text size and the body's own line height.
  static const standard = ReadingStyle();

  final ReadingSize size;
  final ReadingSpacing spacing;

  ReadingStyle copyWith({ReadingSize? size, ReadingSpacing? spacing}) =>
      ReadingStyle(size: size ?? this.size, spacing: spacing ?? this.spacing);

  @override
  List<Object?> get props => [size, spacing];
}

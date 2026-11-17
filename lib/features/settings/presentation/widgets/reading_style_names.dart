import 'package:ai_engineering_bazaar/generated/l10n.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';

/// The name of a text size in the interface's language (plan 12.5).
String readingSizeName(S s, ReadingSize size) => switch (size) {
  ReadingSize.small => s.reading_size_small,
  ReadingSize.standard => s.reading_size_standard,
  ReadingSize.large => s.reading_size_large,
  ReadingSize.larger => s.reading_size_larger,
  ReadingSize.largest => s.reading_size_largest,
};

/// The name of a line spacing in the interface's language (plan 12.5).
String readingSpacingName(S s, ReadingSpacing spacing) => switch (spacing) {
  ReadingSpacing.tight => s.reading_spacing_tight,
  ReadingSpacing.comfortable => s.reading_spacing_comfortable,
  ReadingSpacing.wide => s.reading_spacing_wide,
};

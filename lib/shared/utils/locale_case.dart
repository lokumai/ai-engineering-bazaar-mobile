/// [text] in capitals by the rules of the language [languageCode]: in Turkish and Azerbaijani the capital of "i" is
/// "İ", which Dart's `toUpperCase` makes "I" (so "Sıradaki" came out "SIRADAKI").
String upperCaseIn(String text, String languageCode) => switch (languageCode) {
  'tr' || 'az' => text.replaceAll('i', 'İ').toUpperCase(),
  _ => text.toUpperCase(),
};

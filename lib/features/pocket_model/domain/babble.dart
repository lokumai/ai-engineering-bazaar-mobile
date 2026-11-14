import 'dart:math' as math;

/// What the pocket model says, as a list of tokens (words), and whether it was hallucinating: joining words it never
/// read together.
typedef Babble = ({List<String> tokens, bool hallucinating});

/// Below this temperature the model takes its likeliest word every time.
const double cold = 0.3;

/// What a model that has read nothing writes: two or three strings of letters, as a model with random weights writes
/// noise.
List<String> noise(String language, math.Random random) {
  final letters = _letters[language] ?? _letters['en']!;
  return [
    for (var w = 0; w < 2 + random.nextInt(2); w++)
      String.fromCharCodes([
        for (var c = 0; c < 2 + random.nextInt(4); c++) letters.codeUnitAt(random.nextInt(letters.length)),
      ]),
  ];
}

const _letters = {
  'en': 'abcdefghijklmnopqrstuvwxyz',
  'tr': 'abcçdefgğhıijklmnoöprsştuüvyz',
  'fa': 'ابپتجچحخدرزسشعفقکگلمنوهی',
};

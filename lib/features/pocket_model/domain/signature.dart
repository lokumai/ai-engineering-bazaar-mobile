/// The author's signature (the owner, 2026-11-19): the robot says who wrote it, in its own voice, once it has gone
/// well past the last piece of its wardrobe. Nothing announces it; a reader who keeps going finds it.
library;

/// The level at which the robot says it, once, as it reaches it; from then on now and then when asked to chat.
const signatureLevel = 23;

/// Past [signatureLevel], one chat in this many is the signature.
const signatureOdds = 100;

/// The signature in each of the app's languages, as the robot's words; the name is the same in all three.
const signatures = {
  'en': ['Arda', 'Cengaver', 'wrote', 'me'],
  'tr': ['beni', 'Arda', 'Cengaver', 'yazdı'],
  'fa': ['Arda', 'Cengaver', 'مرا', 'نوشت'],
};

/// The signature in [language], in English where the app has no other.
List<String> signatureIn(String language) => signatures[language] ?? signatures['en']!;

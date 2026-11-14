import 'dart:math' as math;

/// What the pocket model says, as a list of tokens (words), and whether it was hallucinating.
typedef Babble = ({List<String> tokens, bool hallucinating});

/// The pocket model's speech: a toy of the course's ideas, not a language model.
///
/// Its level decides what it can say: at 0 it strings letters, at 1 words picked at random, at 2 a phrase it learnt
/// with many words swapped for others, from 3 the phrase whole, more often the higher the level. The temperature
/// decides how it picks: at the bottom it always says its likeliest phrase; past [hot] it mixes phrases and words, and
/// hallucinates. Overfit, it says the one word it saw most, again and again.
///
/// The phrases speak of tokens, attention and the bazaar; none speaks as a person, as the app's copy does not.
Babble babble({
  required String language,
  required int level,
  required double temperature,
  required bool overfit,
  required math.Random random,
}) {
  final words = _words[language] ?? _words['en']!;
  final phrases = _phrases[language] ?? _phrases['en']!;
  if (overfit) {
    return (tokens: List.filled(4 + random.nextInt(3), words.first), hallucinating: false);
  }
  if (level <= 0) {
    final letters = _letters[language] ?? _letters['en']!;
    return (
      tokens: [
        for (var w = 0; w < 2 + random.nextInt(2); w++)
          String.fromCharCodes([
            for (var c = 0; c < 2 + random.nextInt(4); c++) letters.codeUnitAt(random.nextInt(letters.length)),
          ]),
      ],
      hallucinating: false,
    );
  }
  if (level == 1) {
    return (
      tokens: [for (var w = 0; w < 2 + random.nextInt(3); w++) words[random.nextInt(words.length)]],
      hallucinating: false,
    );
  }
  if (temperature < cold) {
    // The likeliest phrase, every time.
    return (tokens: phrases.first.split(' '), hallucinating: false);
  }
  final hallucinating = temperature >= hot;
  var tokens = phrases[random.nextInt(phrases.length)].split(' ');
  if (hallucinating) {
    // Half of one phrase runs into half of another, and stray words come in.
    final other = phrases[random.nextInt(phrases.length)].split(' ');
    tokens = [...tokens.take((tokens.length / 2).ceil()), ...other.skip(other.length ~/ 2)];
  }
  final swap =
      (switch (level) {
                2 => 0.45,
                3 => 0.2,
                4 => 0.08,
                _ => 0.0,
              } +
              math.max(0, temperature - 1) * 0.35)
          .clamp(0.0, 0.7);
  return (
    tokens: [for (final token in tokens) random.nextDouble() < swap ? words[random.nextInt(words.length)] : token],
    hallucinating: hallucinating,
  );
}

/// Below this temperature the model says its likeliest phrase.
const double cold = 0.3;

/// From this temperature the model hallucinates.
const double hot = 1.4;

const _letters = {
  'en': 'abcdefghijklmnopqrstuvwxyz',
  'tr': 'abcçdefgğhıijklmnoöprsştuüvyz',
  'fa': 'ابپتجچحخدرزسشعفقکگلمنوهی',
};

const _words = {
  'en': [
    'tokens',
    'attention',
    'context',
    'gradient',
    'embedding',
    'weights',
    'layer',
    'loss',
    'prompt',
    'agent',
    'vector',
    'softmax',
    'epoch',
    'batch',
    'bazaar',
    'caravan',
    'camel',
    'tea',
    'lantern',
    'query',
  ],
  'tr': [
    'token',
    'dikkat',
    'bağlam',
    'gradyan',
    'gömme',
    'ağırlık',
    'katman',
    'kayıp',
    'istem',
    'ajan',
    'vektör',
    'softmax',
    'devir',
    'yığın',
    'çarşı',
    'kervan',
    'deve',
    'çay',
    'fener',
    'sorgu',
  ],
  'fa': [
    'توکن',
    'توجه',
    'بافت',
    'گرادیان',
    'بردار',
    'وزن',
    'لایه',
    'خطا',
    'پرامپت',
    'ایجنت',
    'سافت\u200cمکس',
    'دوره',
    'دسته',
    'بازار',
    'کاروان',
    'شتر',
    'چای',
    'فانوس',
    'پرسش',
    'مدل',
  ],
};

const _phrases = {
  'en': [
    'more tokens more wisdom',
    'attention is all the tokens',
    'the loss goes down slowly',
    'the context window is getting full',
    'every layer adds a little meaning',
    'the gradient rolls down the hill',
    'softmax picks the likeliest word',
    'an embedding is a place in a big space',
    'the caravan carries tokens across the desert',
    'a lantern in the bazaar a vector in the dark',
    'next token then the next then the next',
    'temperature up nonsense up',
    'weights remember what the data said',
    'the agent calls a tool and waits',
  ],
  'tr': [
    'daha çok token daha çok bilgelik',
    'dikkat tüm tokenlardır',
    'kayıp yavaş yavaş düşüyor',
    'bağlam penceresi doluyor',
    'her katman biraz anlam katıyor',
    'gradyan tepeden aşağı yuvarlanıyor',
    'softmax en olası sözcüğü seçiyor',
    'gömme büyük bir uzayda bir yer',
    'kervan çölün öbür yanına token taşıyor',
    'çarşıda bir fener karanlıkta bir vektör',
    'sonraki token sonra bir sonraki',
    'sıcaklık artar saçmalık artar',
    'ağırlıklar verinin dediğini hatırlar',
    'ajan bir aracı çağırıp bekliyor',
  ],
  'fa': [
    'توکن بیشتر دانایی بیشتر',
    'توجه همهٔ توکن\u200cهاست',
    'خطا آرام آرام پایین می\u200cآید',
    'پنجرهٔ بافت دارد پر می\u200cشود',
    'هر لایه کمی معنا می\u200cافزاید',
    'گرادیان از تپه پایین می\u200cغلتد',
    'سافت\u200cمکس محتمل\u200cترین واژه را برمی\u200cگزیند',
    'بردار جایی در فضایی بزرگ است',
    'کاروان توکن\u200cها را از بیابان می\u200cبرد',
    'فانوسی در بازار برداری در تاریکی',
    'توکن بعدی و بعدی و بعدی',
    'دما بالا یاوه بالا',
    'وزن\u200cها گفتهٔ داده را به یاد دارند',
    'ایجنت ابزاری را صدا می\u200cزند و منتظر می\u200cماند',
  ],
};

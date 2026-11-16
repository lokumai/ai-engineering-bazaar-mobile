import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_road.dart';
import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';

/// PLACEHOLDER, NOT CONTENT. The Caravan's sample trends, until the bundle carries the author's (web D116,
/// `api/v1/caravan/<lang>.json`); delete this file then.
///
/// These are the web's own sample (`src/components/caravan/sample-trends.ts`, the round-5 mockup's trends), which the
/// web draws while `mini-courses/caravan/trends.yaml` holds none, and says so. Nothing here was researched, measured
/// or checked: the strength is a shape ([strengthShape]), no reading has an address, and the page says it is sample
/// data. The Turkish and Persian words are the app's translation of the web's English sample, so the design can be
/// seen in every language of the app (the owner, 2026-11-14: "the content is not important, the design is").
abstract final class SampleCaravan {
  /// The month the road starts.
  static final DateTime first = DateTime.utc(2022, 11);

  /// The last month the road reaches.
  static final DateTime through = DateTime.utc(2026, 11);

  /// The road of the sample, in [language] (`en`, `tr` or `fa`; English for any other).
  static CaravanRoad road(String language) => CaravanRoad.of(trends(language), first: first, through: through);

  /// The sample trends, in [language].
  static List<CaravanTrend> trends(String language) => [
    for (final row in _rows)
      CaravanTrend(
        id: row.id,
        title: (row.words[language] ?? row.words['en']!).$1,
        text: (row.words[language] ?? row.words['en']!).$2,
        start: _month(row.start),
        end: row.end == null ? null : _month(row.end!),
        peak: row.peak,
        modules: row.modules,
        sources: row.sources,
      ),
  ];

  static DateTime _month(String yearMonth) {
    final [year, month] = yearMonth.split('-');
    return DateTime.utc(int.parse(year), int.parse(month));
  }
}

typedef _Row = ({
  String id,
  String start,
  String? end,
  int peak,
  List<String> modules,
  List<CaravanSourceKind> sources,
  Map<String, (String, String)> words,
});

const _a = CaravanSourceKind.articles;
const _v = CaravanSourceKind.videos;
const _t = CaravanSourceKind.tools;
const _r = CaravanSourceKind.repositories;

const List<_Row> _rows = [
  (
    id: 'chatbot_moment',
    start: '2022-11',
    end: '2023-02',
    peak: 5,
    modules: ['llms'],
    sources: [_a, _v],
    words: {
      'en': (
        'The chatbot moment',
        'A chat window on a language model reached everyone, and talking to a model became ordinary.',
      ),
      'tr': (
        'Sohbet botu anı',
        'Bir dil modelinin üstündeki sohbet penceresi herkese ulaştı ve bir modelle konuşmak sıradan bir şey oldu.',
      ),
      'fa': ('لحظهٔ چت\u200cبات', 'پنجرهٔ گفتگو با یک مدل زبانی به دست همه رسید و حرف زدن با مدل عادی شد.'),
    },
  ),
  (
    id: 'prompt_craft',
    start: '2022-12',
    end: '2023-06',
    peak: 3,
    modules: ['prompt_engineering'],
    sources: [_a],
    words: {
      'en': ('Prompt craft', 'People traded tricks for wording requests, and prompt engineer became a job title.'),
      'tr': (
        'İstem zanaatı',
        'İnsanlar istekleri sözcüklere dökmenin püf noktalarını paylaştı ve istem mühendisi bir iş unvanı oldu.',
      ),
      'fa': ('هنر پرامپت', 'مردم ترفندهای نوشتن درخواست را با هم رد و بدل کردند و مهندس پرامپت عنوان شغلی شد.'),
    },
  ),
  (
    id: 'open_weights',
    start: '2023-02',
    end: '2023-09',
    peak: 4,
    modules: ['training'],
    sources: [_a, _r],
    words: {
      'en': (
        'Open weights spread',
        'Model weights anyone could download began to circulate, and a wave of fine-tunes followed.',
      ),
      'tr': (
        'Açık ağırlıklar yayılıyor',
        'Herkesin indirebildiği model ağırlıkları dolaşmaya başladı, ardından bir ince ayar dalgası geldi.',
      ),
      'fa': (
        'گسترش وزن\u200cهای باز',
        'وزن\u200cهای مدلی که هر کسی می\u200cتوانست دانلود کند دست\u200cبه\u200cدست شد و موجی از تنظیم دقیق در پی آمد.',
      ),
    },
  ),
  (
    id: 'agents_loop',
    start: '2023-04',
    end: '2023-06',
    peak: 4,
    modules: ['agents'],
    sources: [_r],
    words: {
      'en': (
        'Agents that set their own tasks',
        'Loops that let a model choose its next step topped GitHub and promised to run on their own.',
      ),
      'tr': (
        'Kendi görevini koyan ajanlar',
        'Bir modelin sonraki adımını seçmesine izin veren döngüler GitHub’ın zirvesine çıktı ve kendi başlarına '
            'çalışmayı vaat etti.',
      ),
      'fa': (
        'ایجنت\u200cهایی که خودشان کار تعیین می\u200cکنند',
        'حلقه\u200cهایی که به مدل اجازه می\u200cدادند قدم بعدی\u200cاش را انتخاب کند صدر گیت\u200cهاب را گرفتند و وعده دادند خودشان '
            'کار کنند.',
      ),
    },
  ),
  (
    id: 'retrieval',
    start: '2023-04',
    end: '2024-03',
    peak: 4,
    modules: ['rag'],
    sources: [_a, _t],
    words: {
      'en': (
        'Chat with your documents',
        'Retrieval became the usual way to give a model private knowledge, with vector stores everywhere.',
      ),
      'tr': (
        'Belgelerinle sohbet',
        'Bir modele özel bilgi vermenin olağan yolu getirme oldu ve vektör depoları her yerdeydi.',
      ),
      'fa': (
        'گفتگو با اسنادت',
        'بازیابی راه معمول دادن دانش خصوصی به مدل شد و پایگاه\u200cهای برداری همه\u200cجا بودند.',
      ),
    },
  ),
  (
    id: 'gpu_rush',
    start: '2023-05',
    end: '2024-08',
    peak: 3,
    modules: ['inference_providers'],
    sources: [_a],
    words: {
      'en': ('The GPU rush', 'Demand for chips to train and serve models became the industry story.'),
      'tr': ('GPU telaşı', 'Modelleri eğitip sunmak için çip talebi sektörün ana hikâyesi oldu.'),
      'fa': (
        'هجوم برای GPU',
        'تقاضا برای تراشه\u200cهایی که مدل\u200cها را آموزش دهند و اجرا کنند داستان اصلی صنعت شد.',
      ),
    },
  ),
  (
    id: 'tool_calling',
    start: '2023-06',
    end: '2023-12',
    peak: 3,
    modules: ['tools'],
    sources: [_a],
    words: {
      'en': (
        'Models call tools',
        'Models learned to answer with a structured call to a function a developer describes.',
      ),
      'tr': (
        'Modeller araç çağırıyor',
        'Modeller, bir geliştiricinin tarif ettiği bir fonksiyona yapılandırılmış bir çağrıyla yanıt vermeyi öğrendi.',
      ),
      'fa': (
        'مدل\u200cها ابزار صدا می\u200cزنند',
        'مدل\u200cها یاد گرفتند با یک فراخوانی ساخت\u200cیافته به تابعی که توسعه\u200cدهنده توصیف کرده پاسخ دهند.',
      ),
    },
  ),
  (
    id: 'multimodal',
    start: '2023-12',
    end: '2024-06',
    peak: 3,
    modules: ['llms'],
    sources: [_a, _v],
    words: {
      'en': (
        'Models that see and speak',
        'Images, audio and voice became ordinary inputs and outputs of the same model.',
      ),
      'tr': ('Gören ve konuşan modeller', 'Görüntü, ses ve konuşma aynı modelin olağan girdi ve çıktıları oldu.'),
      'fa': ('مدل\u200cهایی که می\u200cبینند و حرف می\u200cزنند', 'تصویر، صوت و صدا ورودی و خروجی عادی همان مدل شدند.'),
    },
  ),
  (
    id: 'long_context',
    start: '2024-02',
    end: '2024-06',
    peak: 3,
    modules: ['context_engineering'],
    sources: [_a],
    words: {
      'en': ('Very long context', 'Context windows grew large enough to hold whole codebases and books.'),
      'tr': ('Çok uzun bağlam', 'Bağlam pencereleri bütün kod tabanlarını ve kitapları alacak kadar büyüdü.'),
      'fa': (
        'بافت بسیار بلند',
        'پنجره\u200cهای بافت آن\u200cقدر بزرگ شدند که کل یک مخزن کد یا یک کتاب را در خود جا دهند.',
      ),
    },
  ),
  (
    id: 'coding_agents',
    start: '2024-03',
    end: '2024-07',
    peak: 4,
    modules: ['coding_agents'],
    sources: [_v, _r],
    words: {
      'en': (
        'Software engineer agents',
        'Demos of agents that plan and write code in their own environment spread widely.',
      ),
      'tr': (
        'Yazılım mühendisi ajanlar',
        'Kendi ortamlarında plan yapıp kod yazan ajanların gösterimleri geniş çapta yayıldı.',
      ),
      'fa': (
        'ایجنت\u200cهای مهندس نرم\u200cافزار',
        'نمایش ایجنت\u200cهایی که در محیط خودشان برنامه\u200cریزی می\u200cکنند و کد می\u200cنویسند همه\u200cجا پخش شد.',
      ),
    },
  ),
  (
    id: 'editor_model',
    start: '2024-06',
    end: '2024-12',
    peak: 3,
    modules: ['coding_agents'],
    sources: [_t],
    words: {
      'en': ('A model in the editor', 'Writing code beside a model inside the editor became a common way to work.'),
      'tr': ('Editörde bir model', 'Editörün içinde bir modelin yanında kod yazmak yaygın bir çalışma biçimi oldu.'),
      'fa': ('مدلی در ویرایشگر', 'کد نوشتن کنار یک مدل درون ویرایشگر شیوهٔ رایج کار شد.'),
    },
  ),
  (
    id: 'reasoning',
    start: '2024-09',
    end: '2025-03',
    peak: 5,
    modules: ['advanced_llm'],
    sources: [_a],
    words: {
      'en': (
        'Models that think first',
        'Models began to spend longer before answering, and test-time compute became a topic.',
      ),
      'tr': (
        'Önce düşünen modeller',
        'Modeller yanıt vermeden önce daha uzun düşünmeye başladı ve test zamanı hesaplama gündeme geldi.',
      ),
      'fa': (
        'مدل\u200cهایی که اول فکر می\u200cکنند',
        'مدل\u200cها پیش از پاسخ وقت بیشتری صرف کردند و محاسبه در زمان آزمون موضوع روز شد.',
      ),
    },
  ),
  (
    id: 'computer_use',
    start: '2024-10',
    end: '2025-04',
    peak: 3,
    modules: ['agents_in_practice'],
    sources: [_a, _v],
    words: {
      'en': (
        'Agents at the screen',
        'Models began to operate a desktop or a browser by reading the screen and clicking.',
      ),
      'tr': (
        'Ekran başında ajanlar',
        'Modeller ekranı okuyup tıklayarak bir masaüstünü ya da tarayıcıyı kullanmaya başladı.',
      ),
      'fa': ('ایجنت\u200cها پشت صفحه', 'مدل\u200cها با خواندن صفحه و کلیک کردن، دسکتاپ یا مرورگر را به کار گرفتند.'),
    },
  ),
  (
    id: 'protocols',
    start: '2024-11',
    end: '2025-07',
    peak: 5,
    modules: ['protocols_reference'],
    sources: [_a, _r],
    words: {
      'en': (
        'Protocols like MCP',
        'An open protocol for connecting models to tools and data spread across labs and editors.',
      ),
      'tr': (
        'MCP gibi protokoller',
        'Modelleri araçlara ve verilere bağlayan açık bir protokol laboratuvarlara ve editörlere yayıldı.',
      ),
      'fa': (
        'پروتکل\u200cهایی مثل MCP',
        'پروتکلی باز برای وصل کردن مدل\u200cها به ابزار و داده در آزمایشگاه\u200cها و ویرایشگرها پخش شد.',
      ),
    },
  ),
  (
    id: 'vibe_coding',
    start: '2025-02',
    end: '2025-08',
    peak: 4,
    modules: ['coding_agents'],
    sources: [_a],
    words: {
      'en': (
        'Vibe coding',
        'A name for building software by describing it to a model spread fast, with its joys and its messes.',
      ),
      'tr': (
        'Vibe coding',
        'Yazılımı bir modele tarif ederek kurmanın adı, sevinçleri ve dağınıklıklarıyla hızla yayıldı.',
      ),
      'fa': (
        'وایب کدینگ',
        'نامی برای ساختن نرم\u200cافزار با توصیف آن برای یک مدل به\u200cسرعت پخش شد، با شادی\u200cها و آشفتگی\u200cهایش.',
      ),
    },
  ),
  (
    id: 'agentic_coding',
    start: '2025-03',
    end: '2026-01',
    peak: 5,
    modules: ['harness_engineering'],
    sources: [_t, _a],
    words: {
      'en': (
        'The agentic coding wave',
        'Agents in the terminal and in the cloud took whole tasks, ran the tests and opened pull requests.',
      ),
      'tr': (
        'Ajanlı kodlama dalgası',
        'Terminaldeki ve buluttaki ajanlar bütün görevleri üstlendi, testleri çalıştırdı ve pull request açtı.',
      ),
      'fa': (
        'موج کدنویسی ایجنتی',
        'ایجنت\u200cها در ترمینال و در ابر کارهای کامل را برعهده گرفتند، تست\u200cها را اجرا کردند و پول\u200cریکوئست باز کردند.',
      ),
    },
  ),
  (
    id: 'context_engineering',
    start: '2025-06',
    end: '2025-12',
    peak: 4,
    modules: ['context_engineering'],
    sources: [_a],
    words: {
      'en': (
        'Deciding what the model sees',
        'The craft moved from wording a prompt to deciding what goes into the context.',
      ),
      'tr': (
        'Modelin ne göreceğine karar vermek',
        'Zanaat, bir istemi sözcüklere dökmekten bağlama neyin gireceğine karar vermeye kaydı.',
      ),
      'fa': (
        'تصمیم دربارهٔ آنچه مدل می\u200cبیند',
        'هنر از نوشتن پرامپت به تصمیم دربارهٔ اینکه چه چیزی وارد بافت شود رسید.',
      ),
    },
  ),
  (
    id: 'skills_harnesses',
    start: '2025-10',
    end: '2026-04',
    peak: 3,
    modules: ['harness_engineering'],
    sources: [_r],
    words: {
      'en': (
        'Skills and harnesses',
        'Folders of instructions and scripts an agent loads when a task needs them, and the harness around the loop.',
      ),
      'tr': (
        'Beceriler ve koşum takımları',
        'Bir ajanın, bir görev gerektirdiğinde yüklediği talimat ve betik klasörleri, ve döngünün çevresindeki koşum.',
      ),
      'fa': (
        'مهارت\u200cها و هارنس\u200cها',
        'پوشه\u200cهایی از دستورالعمل و اسکریپت که ایجنت هنگام نیاز بار می\u200cکند، و هارنسی که دور حلقه است.',
      ),
    },
  ),
  (
    id: 'personal_agents',
    start: '2026-01',
    end: '2026-05',
    peak: 5,
    modules: ['personal_agents'],
    sources: [_r],
    words: {
      'en': ('Agents of your own', 'Self-hosted agents that live in chat apps and run errands topped GitHub trends.'),
      'tr': (
        'Kendine ait ajanlar',
        'Sohbet uygulamalarında yaşayıp işleri halleden, kendi sunucunda çalışan ajanlar GitHub trendlerinin '
            'zirvesine çıktı.',
      ),
      'fa': (
        'ایجنت\u200cهای از آن خودت',
        'ایجنت\u200cهای خودمیزبانی که در اپ\u200cهای گفتگو زندگی می\u200cکنند و کارها را انجام می\u200cدهند صدر ترندهای گیت\u200cهاب را '
            'گرفتند.',
      ),
    },
  ),
  (
    id: 'long_loops',
    start: '2026-03',
    end: '2026-08',
    peak: 3,
    modules: ['loop_engineering'],
    sources: [_a],
    words: {
      'en': ('Long-running loops', 'Agents ran for hours on one task, with checks between rounds.'),
      'tr': (
        'Uzun soluklu döngüler',
        'Ajanlar tek bir görev üzerinde, turlar arasında kontrollerle saatlerce çalıştı.',
      ),
      'fa': ('حلقه\u200cهای طولانی', 'ایجنت\u200cها ساعت\u200cها روی یک کار ماندند، با بررسی میان هر دور.'),
    },
  ),
  (
    id: 'injection',
    start: '2026-05',
    end: '2026-10',
    peak: 3,
    modules: ['security'],
    sources: [_a],
    words: {
      'en': (
        'Injection through the inbox',
        'Prompt injection through tools, pages and email became a regular headline.',
      ),
      'tr': (
        'Gelen kutusundan enjeksiyon',
        'Araçlar, sayfalar ve e-posta üzerinden istem enjeksiyonu düzenli bir manşet oldu.',
      ),
      'fa': ('تزریق از صندوق ورودی', 'تزریق پرامپت از راه ابزارها، صفحه\u200cها و ایمیل تیتر همیشگی خبرها شد.'),
    },
  ),
  (
    id: 'agentic_ui',
    start: '2026-07',
    end: null,
    peak: 2,
    modules: ['ui'],
    sources: [_a, _v],
    words: {
      'en': ('Agents that draw interface', 'Agents began answering with interface instead of a wall of text.'),
      'tr': ('Arayüz çizen ajanlar', 'Ajanlar bir metin duvarı yerine arayüzle yanıt vermeye başladı.'),
      'fa': ('ایجنت\u200cهایی که رابط می\u200cکشند', 'ایجنت\u200cها به جای دیواری از متن با رابط کاربری پاسخ دادند.'),
    },
  ),
];

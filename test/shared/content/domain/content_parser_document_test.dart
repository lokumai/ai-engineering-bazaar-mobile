import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/content_parser.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/documents.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:flutter_test/flutter_test.dart';

import 'content_test_data.dart';

const _modulePath = 'api/v1/modules/alpha/first/en.json';
const _levelPath = 'api/v1/levels/alpha.json';
const _lightSvg = 'api/v1/diagrams/0123456789abcdef0123456789abcdef.svg';
const _darkSvg = 'api/v1/diagrams/fedcba9876543210fedcba9876543210.svg';
const _figure = 'course-images/alpha/figure.png';
const _logo = 'course-images/alpha/logos/mark.svg';

ModuleDoc _parse(Map<String, dynamic> json) =>
    ContentParser.parseModuleDoc(jsonEncode(json), parsedTestIndex(), path: _modulePath);

ModuleDoc parseBody(List<Object?> blocks) => _parse(validModuleDocJson()..['body'] = blocks);

Block _block(Map<String, Object?> json) => parseBody([json]).body!.single;

List<Inline> _inlines(List<Object?> inlines) =>
    (_block({'type': 'paragraph', 'inlines': inlines}) as ParagraphBlock).inlines;

LinkTarget _target(Map<String, Object?> target) =>
    (_inlines([
              {
                'type': 'link',
                'target': target,
                'inlines': [_text('x')],
              },
            ]).single
            as LinkInline)
        .target;

Map<String, Object?> _text(String text) => {'type': 'text', 'text': text};

Map<String, Object?> _paragraph([String text = 'x']) => {
  'type': 'paragraph',
  'inlines': [_text(text)],
};

Map<String, Object?> _image({String src = _figure, Object? number = '1', Object? width = 640}) => {
  'type': 'image',
  'number': number,
  'title': 'Figure',
  'note': 'A note.',
  'src': src,
  'alt': 'A figure',
  'width': width,
  'height': 480,
};

Map<String, Object?> _table({required List<Object?> align, int headCells = 1}) => {
  'type': 'table',
  'number': '2',
  'title': null,
  'rowHeaders': false,
  'align': align,
  'head': [
    for (var i = 0; i < headCells; i++)
      {
        'inlines': [_text('h$i')],
      },
  ],
  'rows': [],
};

Map<String, Object?> _code({String language = 'python', Object? bold = true}) => {
  'type': 'code',
  'language': language,
  'lines': [
    [
      {'text': 'def', 'role': 'keyword', 'bold': bold},
    ],
  ],
};

const _x = [TextInline(text: 'x')];

/// One rejection of a module document: a mutation of the valid document, the field it must be reported at, and why.
typedef _Rejection = ({String field, String why, void Function(Map<String, dynamic> json) mutate});

final List<_Rejection> _rejections = [
  (field: 'schemaVersion', why: 'a major other than 1', mutate: (json) => json['schemaVersion'] = 2),
  (field: 'track', why: 'a track this app does not know', mutate: (json) => json['track'] = 'future'),
  (field: 'dir', why: 'a direction outside the closed set', mutate: (json) => json['dir'] = 'ttb'),
  (
    field: 'toc[0].depth',
    why: 'a depth outside 2 and 3',
    mutate: (json) => ((json['toc'] as List).first as Map)['depth'] = 4,
  ),
  (field: 'body', why: 'body and draft both null', mutate: (json) => json['body'] = null),
  (
    field: 'body',
    why: 'body and draft both present',
    mutate: (json) => json['draft'] = {'summary': null, 'parts': [], 'written': null},
  ),
  (
    field: 'body[0].type',
    why: 'a block without a type',
    mutate: (json) => json['body'] = [
      {
        'inlines': [_text('x')],
      },
    ],
  ),
  (
    field: 'body[0].depth',
    why: 'a heading depth outside 2 to 4',
    mutate: (json) => json['body'] = [
      {'type': 'heading', 'depth': 5, 'id': 'deep', 'inlines': []},
    ],
  ),
  (
    field: 'body[0].kind',
    why: 'a callout kind outside the closed set',
    mutate: (json) => json['body'] = [
      {'type': 'callout', 'kind': 'danger', 'title': null, 'blocks': [], 'action': null},
    ],
  ),
  (
    field: 'body[0].align[0]',
    why: 'an alignment outside the closed set',
    mutate: (json) => json['body'] = [
      _table(align: ['justify']),
    ],
  ),
  (
    field: 'body[0].align',
    why: 'fewer alignments than head cells',
    mutate: (json) => json['body'] = [
      _table(align: [null, null], headCells: 3),
    ],
  ),
  (
    field: 'body[0].number',
    why: 'a caption number that is not digits',
    mutate: (json) => json['body'] = [_image(number: '1a')],
  ),
  (field: 'body[0].width', why: 'a zero width', mutate: (json) => json['body'] = [_image(width: 0)]),
  (
    field: 'body[0].src',
    why: 'an image absent from images',
    mutate: (json) => json['body'] = [_image(src: 'course-images/alpha/other.png')],
  ),
  (
    field: 'body[0].inlines[0].src',
    why: 'a logo absent from images',
    mutate: (json) => json['body'] = [
      {
        'type': 'paragraph',
        'inlines': [
          {'type': 'logo', 'src': 'course-images/alpha/logos/other.svg', 'alt': '', 'mono': false},
        ],
      },
    ],
  ),
  (
    field: 'body[0].svg.dark',
    why: 'a diagram variant absent from files',
    mutate: (json) => json['body'] = [
      {
        'type': 'diagram',
        'number': '3',
        'title': null,
        'svg': {'light': _lightSvg, 'dark': 'api/v1/diagrams/missing.svg'},
      },
    ],
  ),
  (
    field: 'body[0].inlines[0].target.url',
    why: 'an external url that is not http or https',
    mutate: (json) => json['body'] = [
      {
        'type': 'paragraph',
        'inlines': [
          {
            'type': 'link',
            'target': {'kind': 'external', 'url': 'ftp://example.org/'},
            'inlines': [_text('x')],
          },
        ],
      },
    ],
  ),
  (
    field: 'body[0].lines[0][0].bold',
    why: 'bold written as false',
    mutate: (json) => json['body'] = [_code(bold: false)],
  ),
  (field: 'body[0].language', why: 'an empty language', mutate: (json) => json['body'] = [_code(language: '')]),
  (
    field: 'quiz[0].answer',
    why: 'an answer past the last option',
    mutate: (json) => ((json['quiz'] as List).first as Map)['answer'] = 4,
  ),
  (
    field: 'draft.written[0].src',
    why: 'a written draft section holding an image absent from images',
    mutate: (json) => json
      ..['body'] = null
      ..['draft'] = <String, Object?>{
        'summary': null,
        'parts': ['Part one'],
        'written': [_image(src: 'course-images/alpha/other.png')],
      },
  ),
  // Rules beyond the plan's table, each pinning one rule of the type map.
  (
    field: 'quiz[0].answer',
    why: 'a negative answer',
    mutate: (json) => ((json['quiz'] as List).first as Map)['answer'] = -1,
  ),
  (field: 'next.number', why: 'a Ref number below 1', mutate: (json) => (json['next'] as Map)['number'] = 0),
  (
    field: 'objectives.items[0]',
    why: 'an objective that is not a string',
    mutate: (json) => (json['objectives'] as Map)['items'] = [1],
  ),
  (
    field: 'body[0].inlines[0].inlines[0].src',
    why: 'a logo nested in a strong inline absent from images',
    mutate: (json) => json['body'] = [
      {
        'type': 'paragraph',
        'inlines': [
          {
            'type': 'strong',
            'inlines': [
              {'type': 'logo', 'src': 'course-images/alpha/logos/other.svg', 'alt': '', 'mono': true},
            ],
          },
        ],
      },
    ],
  ),
  (
    field: 'body[0].items[0].blocks[0].blocks[0].src',
    why: 'an image in a quote in a list item absent from images',
    mutate: (json) => json['body'] = [
      {
        'type': 'list',
        'ordered': false,
        'items': [
          {
            'blocks': [
              {
                'type': 'quote',
                'blocks': [_image(src: 'course-images/alpha/other.png')],
              },
            ],
          },
        ],
      },
    ],
  ),
  (
    field: 'body[0].rows[0][0].inlines[0].src',
    why: 'a logo in a table cell absent from images',
    mutate: (json) => json['body'] = [
      _table(align: [null])
        ..['rows'] = [
          [
            {
              'inlines': [
                {'type': 'logo', 'src': 'course-images/alpha/logos/other.svg', 'alt': '', 'mono': false},
              ],
            },
          ],
        ],
    ],
  ),
  (
    field: 'body[0].items[0].task.checked',
    why: 'a task item without a checked flag',
    mutate: (json) => json['body'] = [
      {
        'type': 'list',
        'ordered': false,
        'items': [
          {'task': {}, 'blocks': []},
        ],
      },
    ],
  ),
  (
    field: 'body[0].inlines[0].target.kind',
    why: 'a link target without a kind',
    mutate: (json) => json['body'] = [
      {
        'type': 'paragraph',
        'inlines': [
          {
            'type': 'link',
            'target': {'url': 'https://example.org/'},
            'inlines': [],
          },
        ],
      },
    ],
  ),
  (
    field: 'body[0].inlines[0].type',
    why: 'an inline without a type',
    mutate: (json) => json['body'] = [
      {
        'type': 'paragraph',
        'inlines': [
          {'text': 'x'},
        ],
      },
    ],
  ),
  (
    field: 'body[0].lead',
    why: 'lead present but not a boolean',
    mutate: (json) => json['body'] = [_paragraph()..['lead'] = 'yes'],
  ),
];

void main() {
  test('parses the valid module document', () {
    final doc = _parse(validModuleDocJson());
    expect(
      doc,
      const ModuleDoc(
        key: 'alpha/first',
        track: Track.engineers,
        lang: 'en',
        dir: TextDir.ltr,
        title: 'First Module',
        objectives: ['Read a synthetic module.'],
        prerequisites: [],
        previous: null,
        next: Ref(
          key: 'alpha/second',
          number: 2,
          title: 'Second Module',
          drawn: true,
          track: Track.engineers,
          lang: 'en',
        ),
        toc: [TocEntry(id: 'setup', text: 'Setup', depth: 2, mark: 'I')],
        body: [],
        draft: null,
        quiz: [
          QuizItem(question: 'Q?', options: ['a', 'b', 'c', 'd'], answer: 2, explain: 'Because.'),
        ],
      ),
    );
  });

  test('ModuleDoc.toString names the key, the track and the language only', () {
    expect(_parse(validModuleDocJson()).toString(), 'ModuleDoc(alpha/first, engineers, en)');
  });

  test('a parsed document is unmodifiable', () {
    final doc = parseBody([_paragraph()]);
    expect(() => doc.body!.add(const RuleBlock()), throwsUnsupportedError);
    expect(() => doc.toc.clear(), throwsUnsupportedError);
  });

  test('paragraph, lead absent and present', () {
    expect(_block(_paragraph()), const ParagraphBlock(inlines: _x, lead: false));
    expect(_block(_paragraph()..['lead'] = true), const ParagraphBlock(inlines: _x, lead: true));
  });

  test('heading with mark', () {
    expect(
      _block({
        'type': 'heading',
        'depth': 2,
        'id': 'setup',
        'mark': 'I',
        'inlines': [_text('x')],
      }),
      const HeadingBlock(depth: 2, id: 'setup', mark: 'I', inlines: _x),
    );
    expect(
      _block({
        'type': 'heading',
        'depth': 4,
        'id': 'deep',
        'inlines': [_text('x')],
      }),
      const HeadingBlock(depth: 4, id: 'deep', mark: null, inlines: _x),
    );
  });

  test('list: ordered with start, task item', () {
    expect(
      _block({
        'type': 'list',
        'ordered': true,
        'start': 3,
        'items': [
          {
            'task': {'checked': false},
            'blocks': [_paragraph()],
          },
          {
            'blocks': [_paragraph()],
          },
        ],
      }),
      const ListBlock(
        ordered: true,
        start: 3,
        items: [
          ListItem(checked: false, blocks: [ParagraphBlock(inlines: _x, lead: false)]),
          ListItem(checked: null, blocks: [ParagraphBlock(inlines: _x, lead: false)]),
        ],
      ),
    );
    expect(
      _block({'type': 'list', 'ordered': false, 'items': []}),
      const ListBlock(ordered: false, start: null, items: []),
    );
  });

  test('quote with label', () {
    expect(
      _block({
        'type': 'quote',
        'label': 'NOTE',
        'blocks': [_paragraph()],
      }),
      const QuoteBlock(
        label: 'NOTE',
        blocks: [ParagraphBlock(inlines: _x, lead: false)],
      ),
    );
    expect(_block({'type': 'quote', 'blocks': []}), const QuoteBlock(label: null, blocks: []));
  });

  test('callout with title and action', () {
    expect(
      _block({
        'type': 'callout',
        'kind': 'important',
        'title': [_text('x')],
        'blocks': [_paragraph()],
        'action': {
          'target': {'kind': 'external', 'url': 'https://example.org/docs'},
          'inlines': [_text('x')],
        },
      }),
      const CalloutBlock(
        kind: CalloutKind.important,
        title: _x,
        blocks: [ParagraphBlock(inlines: _x, lead: false)],
        action: CalloutAction(
          target: ExternalTarget(url: 'https://example.org/docs'),
          inlines: _x,
        ),
      ),
    );
    for (final kind in CalloutKind.values) {
      expect(
        _block({'type': 'callout', 'kind': kind.name, 'title': null, 'blocks': [], 'action': null}),
        CalloutBlock(kind: kind, title: null, blocks: const [], action: null),
      );
    }
  });

  test('code tokens keep an unknown role and bold true', () {
    expect(
      _block({
        'type': 'code',
        'language': 'python',
        'lines': [
          [
            {'text': 'def', 'role': 'keyword', 'bold': true},
          ],
          [],
          [
            {'text': 'y', 'role': 'future-role'},
          ],
          [
            {'text': 'plain'},
          ],
        ],
      }),
      const CodeBlock(
        language: 'python',
        lines: [
          [CodeToken(text: 'def', role: 'keyword', bold: true)],
          [],
          [CodeToken(text: 'y', role: 'future-role', bold: false)],
          [CodeToken(text: 'plain', role: null, bold: false)],
        ],
      ),
    );
  });

  test('a row shorter than the head is padded with empty cells, and a longer one is cut to it (plan 2.1, GFM)', () {
    Map<String, Object?> cell(String text) => {
      'inlines': [_text(text)],
    };
    expect(
      _block({
        'type': 'table',
        'number': '5',
        'title': null,
        'rowHeaders': false,
        'align': [null, null],
        'head': [cell('a'), cell('b')],
        'rows': [
          [cell('x')],
          [cell('x'), cell('y'), cell('z')],
          [],
        ],
      }),
      const TableBlock(
        number: '5',
        title: null,
        rowHeaders: false,
        align: [null, null],
        head: [
          Cell(inlines: [TextInline(text: 'a')]),
          Cell(inlines: [TextInline(text: 'b')]),
        ],
        rows: [
          [
            Cell(inlines: [TextInline(text: 'x')]),
            Cell(inlines: []),
          ],
          [
            Cell(inlines: [TextInline(text: 'x')]),
            Cell(inlines: [TextInline(text: 'y')]),
          ],
          [Cell(inlines: []), Cell(inlines: [])],
        ],
      ),
    );
  });

  test('table with row headers and align', () {
    expect(
      _block({
        'type': 'table',
        'number': '4',
        'title': 'Numbers',
        'rowHeaders': true,
        'align': ['left', null, 'right'],
        'head': [
          {
            'inlines': [_text('x')],
          },
          {'inlines': []},
          {'inlines': []},
        ],
        'rows': [
          [
            {
              'inlines': [_text('x')],
            },
            {'inlines': []},
            {'inlines': []},
          ],
        ],
      }),
      const TableBlock(
        number: '4',
        title: 'Numbers',
        rowHeaders: true,
        align: [CellAlign.left, null, CellAlign.right],
        head: [
          Cell(inlines: _x),
          Cell(inlines: []),
          Cell(inlines: []),
        ],
        rows: [
          [Cell(inlines: _x), Cell(inlines: []), Cell(inlines: [])],
        ],
      ),
    );
  });

  test('image and diagram', () {
    expect(
      _block(_image(number: '6.1')),
      const ImageBlock(
        number: '6.1',
        title: 'Figure',
        note: 'A note.',
        src: _figure,
        alt: 'A figure',
        width: 640,
        height: 480,
      ),
    );
    expect(
      _block({
        'type': 'diagram',
        'number': '13.2',
        'title': null,
        'svg': {'light': _lightSvg, 'dark': _darkSvg},
      }),
      const DiagramBlock(number: '13.2', title: null, svgLight: _lightSvg, svgDark: _darkSvg),
    );
  });

  test('rule', () {
    expect(_block({'type': 'rule'}), const RuleBlock());
  });

  test('every inline type', () {
    expect(
      _inlines([
        _text('t'),
        {'type': 'code', 'text': 'c'},
        {'type': 'break'},
        {
          'type': 'strong',
          'inlines': [_text('s')],
        },
        {
          'type': 'emphasis',
          'inlines': [_text('e')],
        },
        {
          'type': 'delete',
          'inlines': [_text('d')],
        },
        {
          'type': 'link',
          'target': {'kind': 'anchor', 'id': 'setup'},
          'inlines': [_text('l')],
        },
        {'type': 'logo', 'src': _logo, 'alt': '', 'mono': true},
      ]),
      const [
        TextInline(text: 't'),
        CodeInline(text: 'c'),
        BreakInline(),
        StrongInline(inlines: [TextInline(text: 's')]),
        EmphasisInline(inlines: [TextInline(text: 'e')]),
        DeleteInline(inlines: [TextInline(text: 'd')]),
        LinkInline(
          target: AnchorTarget(id: 'setup'),
          inlines: [TextInline(text: 'l')],
        ),
        LogoInline(src: _logo, alt: '', mono: true),
      ],
    );
  });

  test('every link target kind', () {
    expect(
      _target({'kind': 'module', 'key': 'alpha/second', 'track': 'everyone', 'lang': 'en', 'fragment': 'setup'}),
      const ModuleTarget(key: 'alpha/second', track: Track.everyone, lang: 'en', fragment: 'setup'),
    );
    expect(
      _target({'kind': 'module', 'key': 'alpha/second', 'track': 'engineers', 'lang': 'en'}),
      const ModuleTarget(key: 'alpha/second', track: Track.engineers, lang: 'en', fragment: null),
    );
    expect(
      _target({'kind': 'external', 'url': 'https://example.org/'}),
      const ExternalTarget(url: 'https://example.org/'),
    );
    expect(_target({'kind': 'anchor', 'id': 'setup'}), const AnchorTarget(id: 'setup'));
    expect(_target({'kind': 'catalog'}), const CatalogTarget());
  });

  test('unknown block, inline and target kinds (A23)', () {
    expect(_block({'type': 'carousel', 'items': []}), const UnknownBlock(type: 'carousel'));
    expect(
      _inlines([
        {
          'type': 'sparkle',
          'inlines': [_text('kept')],
        },
        {'type': 'sparkle'},
      ]),
      const [
        UnknownInline(
          type: 'sparkle',
          inlines: [TextInline(text: 'kept')],
        ),
        UnknownInline(type: 'sparkle', inlines: []),
      ],
    );
    expect(_target({'kind': 'webinar'}), const UnknownTarget(kind: 'webinar'));
    expect(
      _target({'kind': 'module', 'key': 'alpha/second', 'track': 'future', 'lang': 'en'}),
      const UnknownTarget(kind: 'module'),
    );
  });

  test('a Ref with an unknown track is not openable', () {
    final json = validModuleDocJson();
    (json['next'] as Map)['track'] = 'future';
    expect(_parse(json).next!.track, isNull);
  });

  test('unknown keys are ignored in the document, a block, an inline, a target and a Ref', () {
    final json = validModuleDocJson()
      ..['extra'] = {'any': 'thing'}
      ..['body'] = [
        {
          'type': 'paragraph',
          'extra': 1,
          'inlines': [
            {
              'type': 'link',
              'extra': true,
              'target': {'kind': 'external', 'url': 'https://example.org/', 'extra': null},
              'inlines': [],
            },
          ],
        },
      ];
    (json['next'] as Map)['extra'] = 'x';
    final plain = validModuleDocJson()
      ..['body'] = [
        {
          'type': 'paragraph',
          'inlines': [
            {
              'type': 'link',
              'target': {'kind': 'external', 'url': 'https://example.org/'},
              'inlines': [],
            },
          ],
        },
      ];
    expect(_parse(json), _parse(plain));
  });

  test('an external url is matched without regard to case', () {
    expect(
      _target({'kind': 'external', 'url': 'HTTPS://example.org/'}),
      const ExternalTarget(url: 'HTTPS://example.org/'),
    );
  });

  test('a draft module', () {
    final json = validModuleDocJson()
      ..['body'] = null
      ..['toc'] = []
      ..['quiz'] = null
      ..['draft'] = <String, Object?>{
        'summary': null,
        'parts': ['Part one'],
        'written': [
          {
            'type': 'heading',
            'depth': 2,
            'id': 'part-one',
            'inlines': [_text('x')],
          },
        ],
      };
    final doc = _parse(json);
    expect(doc.body, isNull);
    expect(doc.quiz, isNull);
    expect(
      doc.draft,
      const Draft(
        summary: null,
        parts: ['Part one'],
        written: [HeadingBlock(depth: 2, id: 'part-one', mark: null, inlines: _x)],
      ),
    );
    (json['draft'] as Map)
      ..['summary'] = 'Soon.'
      ..['written'] = null;
    expect(_parse(json).draft, const Draft(summary: 'Soon.', parts: ['Part one'], written: null));
  });

  test('a level document', () {
    expect(
      ContentParser.parseLevelDoc(
        jsonEncode({
          'schemaVersion': 1,
          'slug': 'alpha',
          'title': 'Alpha',
          'blocks': [_paragraph()..['lead'] = true],
        }),
        parsedTestIndex(),
        path: _levelPath,
      ),
      const LevelDoc(
        slug: 'alpha',
        title: 'Alpha',
        blocks: [ParagraphBlock(inlines: _x, lead: true)],
      ),
    );
  });

  test('rejects (json): an HTML page', () {
    expect(
      () => ContentParser.parseModuleDoc('<!doctype html>', parsedTestIndex(), path: _modulePath),
      throwsA(formatError(_modulePath, '(json)')),
    );
  });

  test('rejects (root): not an object', () {
    expect(
      () => ContentParser.parseLevelDoc('[]', parsedTestIndex(), path: _levelPath),
      throwsA(formatError(_levelPath, '(root)')),
    );
  });

  for (final rejection in _rejections) {
    test('rejects ${rejection.field}: ${rejection.why}', () {
      final json = validModuleDocJson();
      rejection.mutate(json);
      expect(() => _parse(json), throwsA(formatError(_modulePath, rejection.field)));
    });
  }

  test('rejects blocks[0].src: a level document image absent from images', () {
    expect(
      () => ContentParser.parseLevelDoc(
        jsonEncode({
          'schemaVersion': 1,
          'slug': 'alpha',
          'title': 'Alpha',
          'blocks': [_image(src: 'course-images/alpha/other.png')],
        }),
        parsedTestIndex(),
        path: _levelPath,
      ),
      throwsA(formatError(_levelPath, 'blocks[0].src')),
    );
  });

  test('rejects schemaVersion: a level document of another major', () {
    expect(
      () => ContentParser.parseLevelDoc(
        jsonEncode({'schemaVersion': 2, 'slug': 'alpha', 'title': 'Alpha', 'blocks': []}),
        parsedTestIndex(),
        path: _levelPath,
      ),
      throwsA(formatError(_levelPath, 'schemaVersion')),
    );
  });

  group('the story document (web D125)', () {
    const path = 'api/v1/story/en.json';
    Map<String, dynamic> story() => {
      'schemaVersion': 1,
      'lang': 'en',
      'dir': 'ltr',
      'title': 'A Title',
      'stalls': [
        {
          'heading': 'One.',
          'paragraphs': ['First.', 'Second.'],
        },
      ],
      'motto': {
        'lead': 'Lead',
        'lines': ['A.', 'B.'],
      },
    };
    StoryDoc parse(Map<String, dynamic> json) => ContentParser.parseStoryDoc(jsonEncode(json), path: path);

    test('parses the title, the sections and the motto', () {
      expect(
        parse(story()),
        const StoryDoc(
          lang: 'en',
          dir: TextDir.ltr,
          title: 'A Title',
          stalls: [
            StoryStall(heading: 'One.', paragraphs: ['First.', 'Second.']),
          ],
          motto: StoryMotto(lead: 'Lead', lines: ['A.', 'B.']),
        ),
      );
    });

    test('reads a story with no title and no motto, and ignores keys it does not know', () {
      final doc = parse(story()..addAll({'title': null, 'motto': null, 'later': true}));
      expect(doc.title, isNull);
      expect(doc.motto, isNull);
    });

    for (final (field, why, mutate) in <(String, String, void Function(Map<String, dynamic>))>[
      ('schemaVersion', 'a major other than 1', (json) => json['schemaVersion'] = 2),
      ('stalls', 'no section', (json) => json['stalls'] = []),
      ('stalls[0].heading', 'a section with no heading', (json) => (json['stalls'] as List).first.remove('heading')),
      ('dir', 'a direction outside the closed set', (json) => json['dir'] = 'ttb'),
      ('motto.lines', 'missing', (json) => (json['motto'] as Map).remove('lines')),
    ]) {
      test('rejects $field: $why', () {
        final json = story();
        mutate(json);
        expect(() => parse(json), throwsA(formatError(path, field)));
      });
    }
  });
}

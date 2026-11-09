import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

/// A valid `api/v1/index.json` as a fresh, mutable map on every call.
Map<String, dynamic> validIndexJson() => jsonDecode(
  jsonEncode({
    'schemaVersion': 1,
    'contentVersion': 'a' * 64,
    'publishedAt': '2026-01-02T03:04:05.000Z',
    'sourceLanguage': 'en',
    'translations': [],
    'tracks': [
      {'id': 'engineers', 'label': 'For Engineers'},
      {'id': 'everyone', 'label': 'For Everyone'},
    ],
    'diagramFont': {'family': 'Vazirmatn', 'sha256': 'b' * 64},
    'diagramThemes': {
      'light': {'theme': 'default', 'background': 'white'},
      'dark': {'theme': 'dark', 'background': '#333'},
    },
    'levels': [
      {
        'slug': 'alpha',
        'title': 'Alpha',
        'status': 'ready',
        'blurb': '',
        'total': 1,
        'readme': 'api/v1/levels/alpha.json',
      },
    ],
    'modules': [
      {
        'key': 'alpha/first',
        'level': 'alpha',
        'number': 1,
        'minutes': 12,
        'prerequisites': [],
        'tracks': {
          'engineers': {
            'title': 'First Module',
            'drawn': true,
            'summary': null,
            'hasQuiz': true,
            'revision': {'hash': 'abc1234', 'date': '2026-01-01'},
            'docs': {'en': 'api/v1/modules/alpha/first/en.json'},
            'webPath': 'courses/alpha/first/',
          },
          'everyone': {
            'title': 'First Module',
            'drawn': false,
            'summary': null,
            'hasQuiz': false,
            'revision': null,
            'docs': {},
            'webPath': 'everyone/courses/alpha/first/',
          },
        },
      },
    ],
    'moved': {
      'levels': {'gamma': 'alpha'},
      'modules': {'alpha/zeroth': 'alpha/first'},
    },
    'files': {
      'api/v1/levels/alpha.json': 'c' * 64,
      'api/v1/modules/alpha/first/en.json': 'd' * 64,
      'api/v1/diagrams/0123456789abcdef0123456789abcdef.svg': 'f' * 64,
      'api/v1/diagrams/fedcba9876543210fedcba9876543210.svg': '9' * 64,
    },
    'images': {'course-images/alpha/figure.png': 'e' * 64, 'course-images/alpha/logos/mark.svg': '8' * 64},
  }),
) as Map<String, dynamic>;

/// Matches a [ContentFormatException] for the document at [path] and the location [field].
Matcher formatError(String path, String field) =>
    isA<ContentFormatException>().having((e) => e.path, 'path', path).having((e) => e.field, 'field', field);

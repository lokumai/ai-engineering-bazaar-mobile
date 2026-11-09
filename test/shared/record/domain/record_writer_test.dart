import 'dart:convert';

import 'package:ai_engineering_bazaar/shared/record/domain/record_data.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('key order: canonical uint32 keys below 2^32-1 first, numerically, then insertion order', () {
    expect(
      encodeCompact({'x': 1, '42': 2, '01': 3, '4294967295': 4, '4294967294': 5}),
      '{"42":2,"4294967294":5,"x":1,"01":3,"4294967295":4}',
    );
    expect(
      encodeCompact({
        'x': 0,
        '42': 0,
        '01': 0,
        '4294967295': 0,
        '4294967294': 0,
        '0': 0,
        '-1': 0,
        '1.5': 0,
        '007': 0,
        ' 1': 0,
        '4294967296': 0,
      }).replaceAll(':0', ''),
      '{"0","42","4294967294","x","01","4294967295","-1","1.5","007"," 1","4294967296"}',
    );
    expect(
      encodeCompact({
        'z': {
          'y': 1,
          '3': 2,
          'x': {'9': 1, 'q': 2, '8': 3},
        },
        '7': [
          {'b': 1, '1': 2},
        ],
      }),
      '{"7":[{"1":2,"b":1}],"z":{"3":2,"y":1,"x":{"8":3,"9":1,"q":2}}}',
    );
  });
  test('a digit key too long for an int is not an index key', () {
    expect(encodeCompact({'x': 1, '99999999999999999999999': 2, '5': 3}), '{"5":3,"x":1,"99999999999999999999999":2}');
  });
  test('the number rule matches JSON.stringify', () {
    expect(
      encodeCompact([
        9007199254740993,
        -9007199254740993,
        9007199254740992,
        9223372036854775807,
        1e20,
        12345678901234567890.0,
        -0.0,
        3.0,
        1e21,
        0.1,
        1.5e-7,
        1e-7,
        123e-20,
        5e-324,
        1.7976931348623157e308,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        0,
        1,
        -1,
      ]),
      '[9007199254740992,-9007199254740992,9007199254740992,9223372036854776000,100000000000000000000,'
      '12345678901234567000,0,3,1e+21,0.1,1.5e-7,1e-7,1.23e-18,5e-324,1.7976931348623157e+308,null,null,null,0,1,-1]',
    );
    expect(
      encodeCompact(jsonDecode('[1e400,-1e400,-0,-0.0,1.0,1E2,123456789012345678]')),
      '[null,null,0,0,1,100,123456789012345680]',
    );
  });
  test('the smallest int goes through the double rule', () {
    expect(encodeCompact(-9223372036854775807 - 1), '-9223372036854776000');
  });
  test(
    'strings are escaped as JSON.stringify escapes them',
    () => expect(encodeCompact('\u2028/"\\\u0001\uD800'), '"\u2028/\\"\\\\\\u0001\\ud800"'),
  );
  test(
    'export form is JSON.stringify(x, null, 2) with no trailing newline',
    () => expect(
      encodeExport({
        'a': [],
        'b': {},
        'c': [
          1,
          {'d': null},
        ],
      }),
      '{\n  "a": [],\n  "b": {},\n  "c": [\n    1,\n    {\n      "d": null\n    }\n  ]\n}',
    ),
  );
  test('export form orders keys and prints numbers by the same rules', () {
    expect(encodeExport({'b': true, '2': 3.0, 'a': 'x'}), '{\n  "2": 3,\n  "b": true,\n  "a": "x"\n}');
  });
  test('anything that is not JSON is an error', () {
    expect(() => encodeCompact(DateTime(2026)), throwsArgumentError);
    expect(() => encodeExport([Object()]), throwsArgumentError);
    expect(() => encodeCompact({1: 'a'}), throwsArgumentError);
  });
  test(
    'serialise puts schema, savedAt, data first',
    () => expect(
      serialise(RecordData.empty, '2026-03-15T07:10:00.000Z', pretty: false),
      '{"schema":1,"savedAt":"2026-03-15T07:10:00.000Z","data":{"sheets":{},"everyoneSheets":{},"days":[],"prefs":'
      '{"charKeys":true,"railFolded":false,"catalogView":null,"diagramTheme":null,"codePalette":null},'
      '"meta":{"lastExport":null,"persisted":null}}}',
    ),
  );
  test('serialise pretty is the export form of the same envelope', () {
    final pretty = serialise(RecordData.empty, '2026-03-15T07:10:00.000Z', pretty: true);
    expect(pretty, startsWith('{\n  "schema": 1,\n  "savedAt": "2026-03-15T07:10:00.000Z",\n  "data": {\n'));
    expect(pretty, endsWith('\n  }\n}'));
  });
  test('exportFilename', () => expect(exportFilename('2026-03-15T07:10:00.000Z'), 'hl-record-2026-03-15.json'));
}

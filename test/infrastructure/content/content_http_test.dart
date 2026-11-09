import 'dart:async';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/content_fixture.dart';

Matcher _fetchFailure(ContentErrorCode code) =>
    throwsA(isA<ContentFetchException>().having((e) => e.code, 'code', code));

void main() {
  test('a request that does not answer in time is a network failure', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) => Completer<http.Response>().future),
      contentBaseUrl: testContentBaseUrl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
  });

  test('the default timeout is 30 seconds', () => expect(ContentHttp.defaultTimeout, const Duration(seconds: 30)));

  test('a status other than 200 is httpStatus', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => http.Response('', 304)),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.httpStatus));
  });

  test('a client error is a network failure', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => throw http.ClientException('offline')),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
  });

  test('a socket error is a network failure', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => throw const SocketException('unreachable')),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
  });

  test('the request URL joins the base, the path and the version', () async {
    final requested = <Uri>[];
    final contentHttp = ContentHttp(
      client: MockClient((request) async {
        requested.add(request.url);
        return http.Response.bytes([1, 2, 3], 200);
      }),
      contentBaseUrl: testContentBaseUrl,
    );

    expect(await contentHttp.get('api/v1/x.svg', version: 'ab'), [1, 2, 3]);
    expect(requested, [Uri.parse('https://content.test/api/v1/x.svg?v=ab')]);
  });
}

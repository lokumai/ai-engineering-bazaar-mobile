import 'dart:async';
import 'dart:io';

import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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

  test('a download that keeps receiving bytes is not cut by the timeout', () async {
    final contentHttp = ContentHttp(
      client: MockClient.streaming(
        (_, _) async =>
            http.StreamedResponse(Stream.periodic(const Duration(milliseconds: 30), (_) => [7]).take(10), 200),
      ),
      contentBaseUrl: testContentBaseUrl,
      timeout: const Duration(milliseconds: 100),
    );

    expect(await contentHttp.get('api/v1/large.jpeg'), List.filled(10, 7));
  });

  test('a body that goes silent is a network failure, and the request is aborted', () async {
    final requests = <http.BaseRequest>[];
    final contentHttp = ContentHttp(
      client: MockClient.streaming((request, _) async {
        requests.add(request);
        final body = StreamController<List<int>>()..add([1]);
        return http.StreamedResponse(body.stream, 200);
      }),
      contentBaseUrl: testContentBaseUrl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
    await expectLater((requests.single as http.Abortable).abortTrigger, completes);
  });

  test('a request whose head does not arrive in time is aborted', () async {
    final requests = <http.BaseRequest>[];
    final contentHttp = ContentHttp(
      client: MockClient.streaming((request, _) {
        requests.add(request);
        return Completer<http.StreamedResponse>().future;
      }),
      contentBaseUrl: testContentBaseUrl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
    await expectLater((requests.single as http.Abortable).abortTrigger, completes);
  });

  test('the default timeout is 30 seconds', () => expect(ContentHttp.defaultTimeout, const Duration(seconds: 30)));

  test('a status other than 200 is httpStatus', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => http.Response('', 304)),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.httpStatus));
  });

  test('a refused request whose body goes silent is a network failure, and the request is aborted', () async {
    final requests = <http.BaseRequest>[];
    final contentHttp = ContentHttp(
      client: MockClient.streaming((request, _) async {
        requests.add(request);
        final body = StreamController<List<int>>()..add([1]);
        return http.StreamedResponse(body.stream, 503);
      }),
      contentBaseUrl: testContentBaseUrl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
    await expectLater((requests.single as http.Abortable).abortTrigger, completes);
  });

  group('with the real client', () {
    HttpOverrides? overrides;
    HttpServer? server;
    IOClient? client;

    setUp(() {
      // flutter_test answers 400 to every real request through its overrides; this group talks to a loopback server.
      overrides = HttpOverrides.current;
      HttpOverrides.global = null;
    });

    tearDown(() async {
      client?.close();
      await server?.close(force: true);
      HttpOverrides.global = overrides;
    });

    test('a refused request returns its connection, so the next one reuses it', () async {
      final connections = <HttpConnectionInfo>{};
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) {
        connections.add(request.connectionInfo!);
        request.response
          ..statusCode = 503
          ..write('unavailable')
          ..close();
      });
      client = IOClient(HttpClient());
      final contentHttp = ContentHttp(client: client!, contentBaseUrl: 'http://127.0.0.1:${server!.port}/');

      await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.httpStatus));
      await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.httpStatus));

      expect(connections.map((info) => info.remotePort).toSet(), hasLength(1));
    });
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

  test('a TLS failure is a network failure', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => throw const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), _fetchFailure(ContentErrorCode.network));
  });

  test('an error that is not I/O still propagates', () async {
    final contentHttp = ContentHttp(
      client: MockClient((_) async => throw StateError('bug')),
      contentBaseUrl: testContentBaseUrl,
    );

    await expectLater(contentHttp.get('api/index.json'), throwsStateError);
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

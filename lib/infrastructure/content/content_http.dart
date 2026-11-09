import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_url.dart';

/// Fetches site files under the content base URL for a refresh (spec 3.4.4).
final class ContentHttp {
  ContentHttp({required this._client, required this._contentBaseUrl, this._timeout = defaultTimeout});

  /// How long a request may wait for the response head, and then for each next chunk of the body, before the refresh
  /// ends as a network failure (A43, decision E7): a slow download that keeps receiving bytes is not cut.
  static const defaultTimeout = Duration(seconds: 30);

  final http.Client _client;
  final String _contentBaseUrl;
  final Duration _timeout;

  /// The bytes of [sitePath], requested with `?v=<version>` when [version] is given.
  ///
  /// Throws [ContentFetchException] with [ContentErrorCode.network] when the request fails with an I/O error (TLS and
  /// handshake failures included) or goes silent for longer than the timeout, which aborts it, and with
  /// [ContentErrorCode.httpStatus] for any status other than 200, once its body is read. Errors that are not I/O
  /// propagate.
  Future<Uint8List> get(String sitePath, {String? version}) async {
    final url = Uri.parse(joinContentUrl(_contentBaseUrl, sitePath, version: version));
    final abort = Completer<void>();
    try {
      final response = await _client
          .send(http.AbortableRequest('GET', url, abortTrigger: abort.future))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        // Reading the short error body returns the connection to the client's pool; an abort after the head would
        // leave it open and unread for the rest of the session.
        await response.stream.timeout(_timeout).drain<void>();
        throw const ContentFetchException(ContentErrorCode.httpStatus);
      }
      return await http.ByteStream(response.stream.timeout(_timeout)).toBytes();
    } on http.ClientException {
      throw const ContentFetchException(ContentErrorCode.network);
    } on IOException {
      throw const ContentFetchException(ContentErrorCode.network);
    } on TimeoutException {
      abort.complete();
      throw const ContentFetchException(ContentErrorCode.network);
    }
  }
}

/// A request of [ContentHttp] that did not return the file.
final class ContentFetchException implements Exception {
  const ContentFetchException(this.code);

  final ContentErrorCode code;

  @override
  String toString() => 'ContentFetchException(${code.name})';
}

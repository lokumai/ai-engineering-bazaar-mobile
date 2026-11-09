import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ai_engineering_bazaar/shared/content/domain/content_exceptions.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_url.dart';

/// Fetches site files under the content base URL for a refresh (spec 3.4.4).
final class ContentHttp {
  ContentHttp({required this._client, required this._contentBaseUrl, this._timeout = defaultTimeout});

  /// How long a request may take before the refresh ends as a network failure (A43).
  static const defaultTimeout = Duration(seconds: 30);

  final http.Client _client;
  final String _contentBaseUrl;
  final Duration _timeout;

  /// The bytes of [sitePath], requested with `?v=<version>` when [version] is given.
  ///
  /// Throws [ContentFetchException] with [ContentErrorCode.network] when the request fails or does not answer in
  /// time, and with [ContentErrorCode.httpStatus] for any status other than 200.
  Future<Uint8List> get(String sitePath, {String? version}) async {
    final url = Uri.parse(joinContentUrl(_contentBaseUrl, sitePath, version: version));
    final http.Response response;
    try {
      response = await _client.get(url).timeout(_timeout);
    } on http.ClientException {
      throw const ContentFetchException(ContentErrorCode.network);
    } on SocketException {
      throw const ContentFetchException(ContentErrorCode.network);
    } on TimeoutException {
      throw const ContentFetchException(ContentErrorCode.network);
    }
    if (response.statusCode != 200) throw const ContentFetchException(ContentErrorCode.httpStatus);
    return response.bodyBytes;
  }
}

/// A request of [ContentHttp] that did not return the file.
final class ContentFetchException implements Exception {
  const ContentFetchException(this.code);

  final ContentErrorCode code;

  @override
  String toString() => 'ContentFetchException(${code.name})';
}

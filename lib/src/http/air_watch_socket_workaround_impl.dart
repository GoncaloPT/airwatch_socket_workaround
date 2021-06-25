import 'dart:io';

import 'package:airwatch_socket_workaround/src/logger_factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../airwatch_socket_workaround.dart';

/// MethodChannel must match the one listen to in native code
const _httpChannelName = 'org.goncalopt.airWatchSocketWorkAround/http';

/// Implementation of [AirWatchHttpWorkAround]  that relies on
/// a [MethodChannel] to trigger http resquests on the native side
@visibleForTesting
class AirWatchHttpRequestWorkAroundImpl implements AirWatchHttpWorkAround {
  static final _log = getLogger(AirWatchHttpRequestWorkAroundImpl);
  static const defaultPlatform = const MethodChannel(_httpChannelName);

  final MethodChannel platform;
  final HttpRequestBodyProviderFactory _bodyProviderFactory;
  final AirWatchHttpWorkAroundConfiguration _config;

  AirWatchHttpRequestWorkAroundImpl(this._bodyProviderFactory, this._config,
      {this.platform = defaultPlatform});

  @override
  Future<http.Response> doRequest<I>(http.BaseRequest request) async {
    // we want this in production also assert(request.url != null,'request url cannot be null');
    assert(request.method != null, 'request method cannot be null');
    if (request.url == null || request.url.toString().isEmpty)
      throw ArgumentError('request.url cannot be null/empty');
    var requestContentType =
        request.headers['Content-Type'] ?? request.headers['content-type'];

    final contentType = requestContentType != null
        ? ContentType.parse(requestContentType)
        : _config.defaultContentType;
    var bodyProvider = _bodyProviderFactory.build(contentType);
    var body = await bodyProvider.getBody(request);

    Map data = await platform.invokeMethod('doRequest', {
      "url": request.url.toString(),
      "headers": request.headers,
      "method": request.method,
      "body": body
    });

    _log.finest("data is $data");

    // to avoid if != null
    data = data ?? {};
    Map<String, String> headers = {};
    if (data.containsKey('headers')) {
      headers = (data['headers'] as Map<dynamic, dynamic>)
          .map((key, value) => MapEntry(key?.toString(), value?.toString()));
    }

    var statusCode = data["statusCode"] ?? 0;
    return http.Response.bytes(
        bodyProvider.getEncoding(request).encode(data["data"] ?? ''),
        statusCode > 100 ? statusCode : 500,
        headers: headers,
        request: request);
  }
}

class DefaultAirWatchHttpWorkAroundConfiguration
    implements AirWatchHttpWorkAroundConfiguration {
  @override
  ContentType get defaultContentType => ContentType.json;
}

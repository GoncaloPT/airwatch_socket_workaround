import 'package:airwatch_socket_workaround/src/logger_factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../airwatch_socket_workaround.dart';

@visibleForTesting
class AirWatchSocketWorkAroundImpl implements AirWatchSocketWorkAround {
  static final _log = getLogger(AirWatchSocketWorkAroundImpl);
  static const defaultPlatform =
      const MethodChannel('org.goncalopt.airWatchSocketWorkAround/http');

  final MethodChannel platform;
  final HttpRequestBodyProvider _bodyProvider;

  AirWatchSocketWorkAroundImpl(this._bodyProvider,{this.platform = defaultPlatform});

  @override
  Future<http.Response> doRequest<I>(
      http.BaseRequest request) async {
    _log.fine('called w/ method ${request.method},'
        ' url to string ${request.url.toString()},'
        ' body ${_bodyProvider.getBody(request)}'
        ' headers ${request.headers}');

    Map data = await platform.invokeMethod('doRequest', {
      "url": request.url.toString(),
      "headers": request.headers,
      "method": request.method,
      "body": _bodyProvider.getBody(request)
    });

    _log.finest("data is $data");

    Map<String, String> headers = {};
    if (data.containsKey('headers')) {
      headers = (data['headers'] as Map<dynamic, dynamic>)
          .map((key, value) => MapEntry(key?.toString(), value?.toString()));
    }

    return http.Response.bytes(
        (await _bodyProvider.getEncoding(request)).encode(data["data"] ?? ''), data["statusCode"] ?? -1,
        headers: headers, request: request);

  }
}

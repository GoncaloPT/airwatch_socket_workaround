import 'dart:io' as io;

import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

/// Interface with only the required operations for this example.
/// This is just a suggestion of usage.
/// It is not the objective of this plugin/library and by extent also this example
/// to suggest in any way how a Http Client should be implemented
abstract class HttpClient {
  Future<Response> get(String resourceUrl,
      {Map<String, String> additionalHeaders});
}

/// Here the decision of which [HttpClient] to be used is made.
/// In this example, we're just using the platform, but other options
/// could be used, like - for example - receiving a configuration object
class HttpClientFactory {
  HttpClient build() {
    if (io.Platform.isIOS)
      return _AirWatchHttpClient(AirWatchWorkAroundFactory.getInstance());
    return _DartHttpClient();
  }
}

/// 'Normal' implementation of HttpClient which knows nothing
/// about airwatch and just send the requests using dart [HttpClient]
class _DartHttpClient implements HttpClient {
  final Logger _log = Logger('_DartHttpClient');

  @override
  Future<Response> get(String resourceUrl,
      {Map<String, String> additionalHeaders}) async {
    var request = Request("GET", Uri.parse(resourceUrl))
      ..headers.addAll(additionalHeaders ?? _emptyMap);

    _log.fine(
      'called w/ method ${request.method},'
      ' host ${request.url.host},'
      ' port ${request.url.port}'
      ' path ${request.url.path}'
      ' data ${request.body}'
      ' headers ${request.headers}',
    );

    var response = await request.send();
    var streamedResponse = StreamedResponse(
        response.stream, response.statusCode,
        headers: response.headers,
        request: request,
        persistentConnection: response.persistentConnection);

    return Response.fromStream(streamedResponse);
  }
}

const Map<String, String> _emptyMap = {};

/// [HttpClient] that will use the bypass provided by [AirWatchHttpWorkAround]
class _AirWatchHttpClient implements HttpClient {
  final AirWatchHttpWorkAround _nativeClient;

  _AirWatchHttpClient(this._nativeClient);

  @override
  Future<Response> get(String resourceUrl,
      {Map<String, String> additionalHeaders}) async {
    final response = await _nativeClient.doRequest(
        Request("GET", Uri.parse(resourceUrl))
          ..headers.addAll(additionalHeaders ?? _emptyMap));
    return response;
  }
}

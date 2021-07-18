import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:airwatch_socket_workaround/src/websocket/airwatch_websocket.dart';
import 'package:http/http.dart' as http;

import 'http/air_watch_socket_workaround_impl.dart';
import 'http/air_watch_socket_workaround_request.dart';

/// This class was create to ease to task of bypassing underlying dart HTTP client.
/// Why? Because Flutter currently is not respecting system "proxy" and therefore
/// per APN VPN solutions, like vmware AirWatch do not work.
/// Even trying to get the current system proxy DO NOT WORK, since the system proxy
/// is always null.
/// issue exists in flutter: https://github.com/flutter/flutter/issues/41500
///
/// Therefore, this class should only be used in IOS
/// Plugin based Network client
///
/// The responsability of using only in IOS is not enforced in anyway by this class,
/// it is delegated to the client.
abstract class AirWatchHttpWorkAround {
  /// Dispatches HTTP request to the workaround mechanism.
  Future<http.Response> doRequest<I>(http.BaseRequest request);
}

/// Definition of the configurations supported by the system
abstract class AirWatchHttpWorkAroundConfiguration {
  /// Define if you want to fallback to this content-type when none is provided in the Request
  ContentType get defaultContentType;
}

class AirWatchWorkAroundFactory {
  static AirWatchHttpWorkAround getInstance({AirWatchHttpWorkAroundConfiguration config}) {
    config = config ?? DefaultAirWatchHttpWorkAroundConfiguration();
    return AirWatchHttpRequestWorkAroundImpl(
        ContentTypeBasedHttpRequestBodyProviderFactory(), config);
  }

  static Future<AirWatchWebSocketWorkAroundSession<T>> getInstanceSocketSession<T>(String url,
      {AirWatchHttpWorkAroundConfiguration config}) async {
    config = config ?? DefaultAirWatchHttpWorkAroundConfiguration();
    return await NativeWebSocketSession.create<T>(url);
  }
}

/// This  was create to ease to task of bypassing underlying dart socket.
/// Why? Because Flutter currently is not respecting system "proxy" and therefore
/// per APN VPN solutions, like vmware AirWatch do not work.
/// Even trying to get the current system proxy DO NOT WORK, since the system proxy
/// is always null.
/// issue exists in flutter: https://github.com/flutter/flutter/issues/41500
///
/// Therefore, this class should only be used in IOS
/// Plugin based Network client
///
/// The responsability of using only in IOS is not enforced in anyway by this class,
/// it is delegated to the client.
///
/// A corresponding websocket session is maintained in the native side, since
/// all the message exchanges are done there.
abstract class AirWatchWebSocketWorkAroundSession<T> {
  Stream<T> receiveBroadcastStream();

  Future<void> send(String data);

  Future<void> sendByteData(List<int> data);

  StreamSubscription sendFromStream(Stream<String> data);

  Future<void> close();
}

/// Used to obtain the body and encoding
abstract class HttpRequestBodyProvider {
  /// Extracts the actual body from a subtype of [http.BaseRequest]
  Future<dynamic> getBody(http.BaseRequest request);

  Encoding getEncoding(http.BaseRequest request);
}

/// Builds instances of [HttpRequestBodyProvider]
/// Use this per request, so the system can understand what should be the
/// body type of the request.
/// This information will be then used by the native side of the plugin to
/// build the actual Request
abstract class HttpRequestBodyProviderFactory {
  HttpRequestBodyProvider build(ContentType contentType);
}

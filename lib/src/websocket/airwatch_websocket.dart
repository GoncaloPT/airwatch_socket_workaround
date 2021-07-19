import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../air_watch_socket_workaround.dart';
import '../logger_factory.dart';

/// MethodChannel must match the one listen to in native code
const _channelName = 'org.goncalopt.airWatchSocketWorkAround/websocket';

/// Implementation that relies on the platform for websocket communication
class NativeWebSocketSession<T>
    implements AirWatchWebSocketWorkAroundSession<T> {
  static final _log = getLogger(NativeWebSocketSession);
  final MethodChannel _dispatcherMethodChannel;
  final String _eventChannelName;
  final PlatformToWebSocketSessionExceptionMapper _exceptionMapper;
  Stream<T> _stream;

  /// Factory method
  /// builds a [NativeWebSocketSession] using [MethodChannel] to create
  /// a new eventChannel and get the name
  static Future<NativeWebSocketSession<T>> create<T>(String url,
      {PlatformToWebSocketSessionExceptionMapper exceptionMapper =
          _defaultPlatformToWebSocketSessionExceptionMapper}) async {
    try {
      final eventChannelNameFinderMethodChanel = MethodChannel(_channelName);
      var evtChannelName = await eventChannelNameFinderMethodChanel
          .invokeMethod("createAndGetEventChannelName", {"url": url});
      return NativeWebSocketSession._(
          eventChannelNameFinderMethodChanel, evtChannelName, exceptionMapper);
    } on Exception catch (error, stackstrace) {
      _log.severe(" $error $stackstrace");
      return Future.error(error);
    }
  }

  NativeWebSocketSession._(this._dispatcherMethodChannel,
      this._eventChannelName, this._exceptionMapper)
      : assert(_dispatcherMethodChannel != null),
        assert(
          _eventChannelName != null,
        );

  @override
  Stream<T> receiveBroadcastStream() {
    // TODO safe to do this?
    _stream ??= EventChannel(_eventChannelName)
        .receiveBroadcastStream()
        .handleError((var error, var stackTrace) {
      _log.warning('Error from native socket $error');
      if (error is PlatformException) {
        throw _exceptionMapper(error);
      }
      throw error;
    }).cast();
    return _stream;
  }

  /// implNotes: We cannot use the eventChannel name to send since ios will not
  /// be listening to it
  @override
  Future<void> send(String data) {
    return _dispatcherMethodChannel.invokeMethod("sendMessage", {
      "eventChannelName": "$_eventChannelName",
      "body": "$data",
    });
  }

  // implNotes: Uses [Uint8List] that maps to:
  // - java byte[]
  // - swift FlutterStandardTypedData
  // more info: https://flutter.dev/docs/development/platform-integration/platform-channels
  @override
  Future<void> sendByteData(List<int> elements) {
    var data = Uint8List.fromList(elements);
    return _dispatcherMethodChannel.invokeMethod("sendByteData", {
      "eventChannelName": "$_eventChannelName",
      "body": data,
    });
  }

  @override
  StreamSubscription sendFromStream(Stream<String> data) => data.listen(send);

  @override
  Future<void> close() async {
    // force closing on the native side
    await (_stream ?? EventChannel(_eventChannelName).receiveBroadcastStream())
        .listen((event) {})
        .cancel();
  }
}

class WebSocketSessionException implements Exception {
  final WebSocketSessionExceptionType type;
  final String message;
  final String details;
  final String stacktrace;

  WebSocketSessionException(this.type,
      {this.message, this.details, this.stacktrace});
}

/// Translates between [PlatformException] and [WebSocketSessionException]
///
typedef PlatformToWebSocketSessionExceptionMapper = WebSocketSessionException
    Function(PlatformException platformException);

WebSocketSessionException _defaultPlatformToWebSocketSessionExceptionMapper(
    PlatformException platformException) {
  WebSocketSessionExceptionType exceptionType =
      WebSocketSessionExceptionType.unmappedExceptionType;
  switch (platformException.code) {
    case "failureReceivingMessageFromSocket":
      exceptionType =
          WebSocketSessionExceptionType.failureReceivingMessageFromSocket;
      break;
    case "unknownContentTypeFromServerMessage":
      exceptionType =
          WebSocketSessionExceptionType.unknownContentTypeFromServerMessage;
      break;
    case "illegalArguments":
      exceptionType = WebSocketSessionExceptionType.illegalArguments;
      break;
    case "noSocketOrSocketClosed":
      exceptionType = WebSocketSessionExceptionType.noSocketOrSocketClosed;
      break;
  }
  return WebSocketSessionException(exceptionType,
      message: platformException.message,
      details: platformException.details,
      stacktrace: platformException.stacktrace);
}

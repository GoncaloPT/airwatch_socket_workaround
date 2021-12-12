import 'dart:convert';
import 'dart:io';
import 'package:airwatch_socket_workaround/src/http/air_watch_socket_workaround_request.dart';
import 'package:http_parser/http_parser.dart';
import 'package:airwatch_socket_workaround/src/http/air_watch_socket_workaround_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';


/// Tests for the air_watch_socket_workaround.dart classes.
/// These are unit test, not integration tests.
/// Therefore the actual MethodChannel is mocked, which means
/// that the native implementation part of the plugin IS NOT tested by this set of unit tests
void main() {
  // this method mocks the MethodChannel
  const MethodChannel channel =
      MethodChannel('org.goncalopt.airWatchSocketWorkAround/http');
  TestWidgetsFlutterBinding.ensureInitialized();
  var defaultConfig = DefaultAirWatchHttpWorkAroundConfiguration();

  group('implementation resilience', () {
    var airWatchSocketWorkAround = AirWatchHttpRequestWorkAroundImpl(
      HttpRequestBodyProviderImpl(),
      defaultConfig,
    );

    tearDown(() {
      channel.setMockMethodCallHandler(null);
    });

    test('empty content type in the request should assume default', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = utf8.encode('');
      });
      var response = await airWatchSocketWorkAround
          .doRequest(Request('GET', Uri.parse('http://localhost:8080')));
      expect(response.statusCode, 200);
    });

    test('empty content type in the request should assume default', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = utf8.encode('');
      });
      var response = await airWatchSocketWorkAround.doRequest(
          Request('GET', Uri.parse('http://localhost:8080'))..body = "{}");
      expect(response.statusCode, 200);
    });

    test('empty response from method handler should result in 500', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return null;
      });
      var response = await airWatchSocketWorkAround
          .doRequest(Request('GET', Uri.parse('http://localhost:8080')));
      expect(response.statusCode, 500);
    });

    test('empty body in the request should be supported', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = utf8.encode('');
      });
      var response = await airWatchSocketWorkAround
          .doRequest(Request('GET', Uri.parse('http://localhost:8080')));
      expect(response.statusCode, 200);
    });
  });

  group('send String body', () {
    var airWatchSocketWorkAround = AirWatchHttpRequestWorkAroundImpl(
      HttpRequestBodyProviderImpl(),
      defaultConfig,
    );
    var dummyMethodCallResponseData = '''{
          'dummy': 1,
          'stringDummy':2
        }''';

    tearDown(() {
      channel.setMockMethodCallHandler(null);
    });
    var contentType = ContentType.json;
    test('should be able to send json payload', () async {
      // the request will be short-circuited as response
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = methodCall.arguments['body'];
      });

      var request = Request('GET', Uri.parse('http://localhost:8080/'))
        ..bodyBytes = utf8.encode(dummyMethodCallResponseData)
        ..encoding = utf8
        ..headers.addAll({'Content-Type': contentType.value});

      var result = await airWatchSocketWorkAround.doRequest(request);

      expect(result.body, equals(dummyMethodCallResponseData));
      expect(result.statusCode, equals(200));
    });
    test(
        'should be prepared for eventual -1 status codes and empty data argument',
        () async {
      // the request will be short-circuited as response
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return methodCall.arguments
          ..['statusCode'] = -1
          ..['data'] = null;
      });

      var request = Request('GET', Uri.parse('http://localhost:8080/'))
        ..bodyBytes = utf8.encode(dummyMethodCallResponseData)
        ..encoding = utf8
        ..headers.addAll({'Content-Type': contentType.value});

      var result = await airWatchSocketWorkAround.doRequest(request);
      expect(result.statusCode, equals(500));
      channel.setMockMethodCallHandler(null);
    });
  });

  group('send byte array', () {
    var airWatchSocketWorkAround = AirWatchHttpRequestWorkAroundImpl(
      HttpRequestBodyProviderImpl(),
      defaultConfig,
    );
    var contentType = ContentType.binary;
    var dummyMethodCallResponse = 'atest';
    test('should be able to send binary payload', () async {
      // the request will be short-circuited as response
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        print(methodCall.arguments);
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = methodCall.arguments['body'];
      });
      var request = Request('GET', Uri.parse('http://localhost:8080/'))
        ..bodyBytes = utf8.encode(dummyMethodCallResponse)
        ..headers.addAll({'Content-Type': contentType.value});

      var result = await airWatchSocketWorkAround.doRequest(request);
      expect(result.body, equals(dummyMethodCallResponse));
      expect(result.statusCode, equals(200));
    });
  });
  group('send multipart request', () {
    var data = utf8.encode("ola");
    var contentType = ContentType.binary;
    var airWatchSocketWorkAround = AirWatchHttpRequestWorkAroundImpl(
      HttpRequestBodyProviderImpl(),
      defaultConfig,
    );

    test('should be able to send binary payload', () async {
      var dummyMethodCallResponse = MultipartFile(
          'test', ByteStream.fromBytes(data), data.length,
          filename: 'test',
          contentType: MediaType(contentType.primaryType, contentType.subType));

      // the request will be short-circuited as response
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        print(methodCall.arguments);
        return methodCall.arguments
          ..['statusCode'] = 200
          ..['data'] = utf8.encode('[]');
      });
      var request = MultipartRequest('GET', Uri.parse('http://localhost:8080/'))
        ..files.add(dummyMethodCallResponse)
        ..headers.addAll({'Content-Type': 'multipart/form-data'});

      var result = await airWatchSocketWorkAround.doRequest(request);
      expect(result.body, equals(jsonEncode([])));
      expect(result.statusCode, equals(200));
    });
  });
}

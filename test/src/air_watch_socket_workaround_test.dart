import 'dart:convert';

import 'package:airwatch_socket_workaround/src/air_watch_socket_workaround_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:http/http.dart';

void main() {
  // this method mocks the MethodChannel
  const MethodChannel channel = MethodChannel(
      'org.goncalopt.airWatchSocketWorkAround/http');
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return dummyMethodCallResponse;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('send String body', () {
    test('should be able to parse json response', () async {
      AirWatchSocketWorkAround airWatchSocketWorkAround = AirWatchSocketWorkAroundImpl();
      var request = Request('GET', Uri.parse('http://localhost:8080/'))
        ..body = jsonEncode(dummyMethodCallResponse)
        ..encoding = utf8
        ..headers.addAll({'Content-Type': 'application/json'});
      var result = await airWatchSocketWorkAround.doRequest(request);

      expect(result.body, equals(jsonEncode(dummyMethodCallResponse)));
          expect(result.statusCode, equals(200));
    });
  });

  group('send byte array', () {
    test('should be able to parse json response', () async {

    });
  });
}

var dummyMethodCallResponse = {
  'statusCode': 200,
  'headers': {
    'contentType': 'application/json'
  },
  'data': '''{
          'dummy': 1,
          'stringDummy':2
        }'''
};

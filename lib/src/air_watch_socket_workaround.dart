import 'dart:convert';
import 'dart:typed_data';

import 'package:airwatch_socket_workaround/src/logger_factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;



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
abstract class AirWatchSocketWorkAround {
  /// Dispatchs request to the workaround mechanism.
  Future<http.Response> doRequest<I>(
      http.BaseRequest request);
}

abstract class HttpRequestBodyProvider {
  Future<dynamic> getBody(http.BaseRequest request);
  Encoding getEncoding(http.BaseRequest request);
}




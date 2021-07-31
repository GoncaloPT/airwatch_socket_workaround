import 'package:airwatch_socket_workaround_example/logging.dart';
import 'package:airwatch_socket_workaround_example/src/domain/http.dart';
import 'package:airwatch_socket_workaround_example/src/presentation/http_tryout_widget.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:logging/logging.dart';

import 'src/presentation/ws_example_widget.dart';

void main() {
  /// dependencies wire block
  var httpClient = HttpClientFactory().build();
  configureConsoleLogger(1);
  Logger("App").level = Level.FINEST;
  Logger("airwatch_socket_workaround").level = Level.FINEST;

  /// end dependencies wire block
  runApp(MyApp(httpClient: httpClient));
}

class MyApp extends StatefulWidget {
  final HttpClient httpClient;

  const MyApp({Key key, @required this.httpClient}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  text: 'HTTP',
                ),
                Tab(
                  text: 'MULTIPART',
                ),
                Tab(
                  text: 'WEBSOCKET',
                ),
              ],
            ),
            title: Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              HttpTryoutWidget(widget.httpClient),
              Center(
                child: Text(
                  'TODO',
                  style: theme.textTheme.headline2,
                ),
              ),
              WsExampleWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:airwatch_socket_workaround_example/src/domain/http.dart';
import 'package:airwatch_socket_workaround_example/src/presentation/http_tryout_widget.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';


void main() {
  /// dependencies wire block
  var httpClient = HttpClientFactory().build();
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
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      //platformVersion = await AirwatchSocketWorkaround.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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
              Center(
                child: Text(
                  'TODO',
                  style: theme.textTheme.headline2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

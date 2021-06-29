import 'dart:async';

import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as dartHttp;

class HttpTryoutWidget extends StatefulWidget {
  const HttpTryoutWidget({Key key}) : super(key: key);

  @override
  _HttpTryoutWidgetState createState() => _HttpTryoutWidgetState();
}

class _HttpTryoutWidgetState extends State<HttpTryoutWidget> {
  var responseText = '';
  var endpoint = 'https://jsonplaceholder.typicode.com/todos/1';
  var wsEndpoint = 'wss://echo.websocket.org';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SendHttpRequestWidget('Http request',wsEndpoint,),
        /*buildHttpGetWidget('Websocket echo', (endpoint) async {
          var session =
              await AirWatchWorkAroundFactory.getInstanceSocketSession(
                  endpoint);
          var stream = session.receiveBroadcastStream();
          session.send('hello');
          return stream;
        }),*/
      ],
    );
  }
}

class SendHttpRequestWidget extends StatefulWidget {
  final String _title;
  final String _endpoint;

  const SendHttpRequestWidget(this._title, this._endpoint, {Key key})
      : super(key: key);

  @override
  _SendHttpRequestWidgetState createState() => _SendHttpRequestWidgetState();
}

class _SendHttpRequestWidgetState extends State<SendHttpRequestWidget> {
  final StreamController<String> responseStream = StreamController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: responseStream.stream,
        builder: (context, snapshot) {
          return Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget._title,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Flex(
                direction: Axis.horizontal,
                children: [
                  Flexible(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      child: TextField(
                        onChanged: (value) {
                          responseStream.add(value);
                        },
                        controller: TextEditingController()..text = widget._endpoint,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(), hintText: 'endpoint'),
                      ),
                    ),
                  ),
                  MaterialButton(
                    child: Text('Send'),
                    onPressed: () async {
                      setState(() {
                        //responseText = '';
                      });

                      AirWatchHttpWorkAround httpWorkAroundClient =
                          AirWatchWorkAroundFactory.getInstance();
                      var request = dartHttp.Request(
                          "GET", Uri.parse(widget._endpoint))
                        ..headers.addAll({'content-type': 'application/json'});
                      var response =
                          await httpWorkAroundClient.doRequest(request);
                      responseStream.add(response.body);
                    },
                  )
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                alignment: AlignmentDirectional.centerStart,
                child: Text('response was $snapshot'),
              )
            ],
          );
        });
  }
}

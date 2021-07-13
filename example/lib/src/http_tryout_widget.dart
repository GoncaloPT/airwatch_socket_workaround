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
  var wsEndpoint = 'https://httpbin.org/anything';

  @override
  Widget build(BuildContext context) {
    return SendHttpRequestWidget(
      (String endpoint) async {
        AirWatchHttpWorkAround httpWorkAroundClient =
            AirWatchWorkAroundFactory.getInstance();
        var request = dartHttp.Request("GET", Uri.parse(endpoint))
          ..headers.addAll({'content-type': 'application/json'});
        var response = await httpWorkAroundClient.doRequest(request);

        return '${response.body}';
      },
      wsEndpoint,
    );
  }
}

class SendHttpRequestWidget extends StatefulWidget {
  final String _endpoint;
  final Future<String> Function(String) doRequest;

  const SendHttpRequestWidget(this.doRequest, this._endpoint, {Key key})
      : super(key: key);

  @override
  _SendHttpRequestWidgetState createState() => _SendHttpRequestWidgetState();
}

class _SendHttpRequestWidgetState extends State<SendHttpRequestWidget> {
  final StreamController<String> responseStream = StreamController();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return StreamBuilder<String>(
        stream: responseStream.stream,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            child: Flex(
              direction: Axis.vertical,
              children: [
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
                          controller: TextEditingController()
                            ..text = widget._endpoint,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'endpoint'),
                        ),
                      ),
                    ),
                    MaterialButton(
                      child: Text('Send'),
                      onPressed: () async {
                        setState(() {
                          responseStream.add('');
                        });

                        var responseString =
                            await widget.doRequest(widget._endpoint);
                        print('response string: $responseString');
                        responseStream.add(responseString);
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    direction: Axis.horizontal,
                    spacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'response is',
                        style: theme.textTheme.headline3,
                      ),
                      Text('${snapshot.data}'),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }
}

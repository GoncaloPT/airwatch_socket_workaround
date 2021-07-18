import 'dart:async';

import 'package:airwatch_socket_workaround_example/src/domain/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as dartHttp;

class HttpTryoutWidget extends StatefulWidget {
  /// this is just for the sake of example, in real world scenario this would
  /// probably be in a 'service' or such
  final HttpClient _httpClient;

  const HttpTryoutWidget(
    this._httpClient, {
    Key key,
  }) : super(key: key);

  @override
  _HttpTryoutWidgetState createState() => _HttpTryoutWidgetState();
}

class _HttpTryoutWidgetState extends State<HttpTryoutWidget> {
  var responseText = '';
  var endpoint = 'https://jsonplaceholder.typicode.com/todos/1';

  @override
  Widget build(BuildContext context) {
    return SendHttpRequestWidget(
      (String endpoint) async {
        var response = await widget._httpClient.get(endpoint);
        return '${response.body}';
      },
    );
  }
}

class SendHttpRequestWidget extends StatefulWidget {

  final Future<String> Function(String) doRequest;

  const SendHttpRequestWidget(this.doRequest,  {Key key})
      : super(key: key);

  @override
  _SendHttpRequestWidgetState createState() => _SendHttpRequestWidgetState();
}

class _SendHttpRequestWidgetState extends State<SendHttpRequestWidget> {
  final StreamController<String> responseStream = StreamController();
  var _endpoint= 'https://httpbin.org/anything';

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
                            _endpoint = value;
                          },
                          controller: TextEditingController()
                            ..text = _endpoint,
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
                            await widget.doRequest(_endpoint);
                        print('response string: $responseString');
                        responseStream.add(responseString);
                      },
                    )
                  ],
                ),
                if (snapshot.hasData)
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

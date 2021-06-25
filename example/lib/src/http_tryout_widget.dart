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
        buildHttpGetWidget('HTTP GET', (endpoint) async {
          AirWatchHttpWorkAround httpWorkAroundClient =
              AirWatchWorkAroundFactory.getInstance();
          var request = dartHttp.Request("GET", Uri.parse(endpoint))
            ..headers.addAll({'content-type': 'application/json'});
          var response = await httpWorkAroundClient.doRequest(request);
          return Stream.value(response.body);
        }),
        Padding(
          padding: EdgeInsets.all(8),
          child: Divider(
            height: 8.0,
          ),
        ),
        buildHttpGetWidget('Websocket echo', (endpoint) async {
          var session =
              await AirWatchWorkAroundFactory.getInstanceSocketSession(
                  endpoint);
          var stream = session.receiveBroadcastStream();
          session.send('hello');
          return stream;
        }),
      ],
    );
  }

  Widget buildHttpGetWidget(
      String title, Future<Stream<String>> doRequest(String endpoint)) {
    return Flex(
      direction: Axis.vertical,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextField(
                  onChanged: (value) {
                    wsEndpoint = value;
                  },
                  controller: TextEditingController()..text = wsEndpoint,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), hintText: 'endpoint'),
                ),
              ),
            ),
            MaterialButton(
              child: Text('Send'),
              onPressed: () async {
                setState(() {
                  responseText = '';
                });

                var response = await doRequest(wsEndpoint);
                response.listen((event) {
                  setState(() {
                    responseText = event;
                  });
                });
              },
            )
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          alignment: AlignmentDirectional.centerStart,
          child: Text('response was $responseText'),
        )
      ],
    );
  }
}

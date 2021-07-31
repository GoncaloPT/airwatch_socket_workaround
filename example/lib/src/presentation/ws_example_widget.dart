import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class WsExampleWidget extends StatefulWidget {
  const WsExampleWidget({Key key}) : super(key: key);

  @override
  _WsExampleWidgetState createState() => _WsExampleWidgetState();
}

class _WsExampleWidgetState extends State<WsExampleWidget> {
  var _log = Logger("_WsExampleWidgetState");
  var responses = <String>[];
  var _textToSend = 'hello';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return FutureBuilder(
        future: AirWatchWorkAroundFactory.getInstanceSocketSession<String>(
            "wss://echo.websocket.org"),
        builder: (BuildContext context,
            AsyncSnapshot<AirWatchWebSocketWorkAroundSession<String>>
                snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          var wsStream = snapshot.data;
          return StreamBuilder(
              stream: wsStream.receiveBroadcastStream(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasError) {
                  _log.warning("error on stream: ${snapshot.error}");
                }
                print('building ${snapshot.hasData}');
                if (snapshot.hasData) {
                  responses.add('response: ${snapshot.data}');
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    Text(

                      "This widget is using echo websocket.\n"
                      "Enter the text you and to send and press send.\n"
                      "After sending you should se bellow the "
                      "response from the echo service",
                      style: theme.textTheme.headline6,
                      textAlign: TextAlign.start,
                    ),
                    Flex(
                      direction: Axis.horizontal,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            child: TextField(
                              onChanged: (value) {
                                _textToSend = value;
                              },
                              controller: TextEditingController()
                                ..text = _textToSend,
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'text to send'),
                            ),
                          ),
                        ),
                        RaisedButton(
                          child: Text('Send'),
                          onPressed: () async {
                            wsStream.send(_textToSend);
                          },
                        )
                      ],
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) => Text(responses[index]),
                      itemCount: responses.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(),
                    ),
                  ]),
                );
              });
        });
  }
}

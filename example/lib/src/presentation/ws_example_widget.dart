import 'package:airwatch_socket_workaround/airwatch_socket_workaround.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WsExampleWidget extends StatefulWidget {
  const WsExampleWidget({Key key}) : super(key: key);

  @override
  _WsExampleWidgetState createState() => _WsExampleWidgetState();
}

class _WsExampleWidgetState extends State<WsExampleWidget> {
  var responses = <String>[];
  var _textToSend = 'hello';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                print('building ${snapshot.hasData}');
                if (snapshot.hasData) {
                  responses.add(snapshot.data);
                }
                return Column(children: [
                  Flex(
                    direction: Axis.horizontal,
                    children: [
                      Flexible(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _textToSend = value;
                              });

                            },
                            controller: TextEditingController()
                              ..text = _textToSend,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'text to send'),
                          ),
                        ),
                      ),
                      MaterialButton(
                        child: Text('Send'),
                        onPressed: () async {
                          print('Send called!!');
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
                ]);
              });
        });
  }
}

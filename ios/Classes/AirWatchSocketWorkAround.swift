///
///  AirWatchWorkaround.swift
///  Runner
///
///  Created by Gonçalo Silva  on 05/03/2021.
///
///  The goal of this class is to provide a TEMPORARY workaround that allows the usage
///  of websockets to communicate with protected domains, which are currently inside closed network.
///  Therefore, to access them, IOS uses perAppVpn. Per app vpn is not working when the request
///  is originated from DART VM.
///  Issues:
///        DART => https://github.com/dart-lang/sdk/issues/41376
///        FLutter => https://github.com/flutter/flutter/issues/41500
///  Once this issues are solved, or backend is moved to a public hosted cloud, this class should be deprecated!
///
/// ** DISCLAMER ** This was built to be a workaround, not a permanent solution ( as always xD ). Unfortunatly, until this moment,  the flutter team haven't provided the desired solution
import Flutter
import UIKit
import os

public class AirWatchSocketWorkAround: NSObject {



    static var webSocketChannelName = "org.goncalopt.airWatchSocketWorkAround/websocket"
    var openChannelsDicionary:SharedDictionary = SharedDictionary<String, AirWatchWorkaroundWebSocketClient>()
    private var messenger: FlutterBinaryMessenger!

    // builder method for AirWatchSocketWorkAround
    public static func register(with registrar: FlutterPluginRegistrar) {
        os_log("AirWatchSocketWorkAround.register called. Please make sure this is still needed, since it's a workaround!! ",log: OSLog.airWatchWorkaroundHttpClient,type: .info)
        let airWatchSocketWorkAround = AirWatchSocketWorkAround(messenger :registrar.messenger())
        let webSocketChannel = FlutterMethodChannel(name: AirWatchSocketWorkAround.webSocketChannelName, binaryMessenger: registrar.messenger())
        webSocketChannel.setMethodCallHandler(airWatchSocketWorkAround.handle)


    }


    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger

    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard call.method == "createAndGetEventChannelName" ||  call.method == "sendMessage"
        || call.method == "sendByteData"
        else{
            result(FlutterMethodNotImplemented)
            return
        }

        switch call.method {
        case "createAndGetEventChannelName":
            os_log("createAndGetEventChannelName called",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info)

            let args = call.arguments as! NSDictionary
            guard args["url"] != nil else{
                os_log("createAndGetEventChannelName: url cannot be null",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error)
                result(FlutterError(code: "arguments_missing", message: "url cannot be null", details: nil))
                return ;
            }
            let url = args["url"] as! String
            // appends webSocketChannelName with the current timestamp
            let newEventChannelName = "\(AirWatchSocketWorkAround.webSocketChannelName)_\(NSDate().timeIntervalSince1970)";
            os_log("createAndGetEventChannelName: creating a newEventChannelName %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .debug, String(describing: newEventChannelName))

            do{
                os_log("createAndGetEventChannelName: before creating WebSocketStreamHandler",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info)
                let streamHandler =  try WebSocketStreamHandler(channelName: newEventChannelName, openChannelsDicionary: openChannelsDicionary, url: url)
                //websocket event channel
                let eventChannel = FlutterEventChannel(name: newEventChannelName, binaryMessenger: messenger)
                eventChannel.setStreamHandler(streamHandler)

                os_log("createAndGetEventChannelName: returning newEventChannelName %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info, String(describing: newEventChannelName))
                result("\(newEventChannelName)")
            }
            catch{
                os_log("Error when creating WebSocketStreamHandler %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                result("Error when creating WebSocketStreamHandler: \(error)")
            }

        case "sendMessage":
            let args = call.arguments as! NSDictionary
            guard args["eventChannelName"] != nil else{
                result(FlutterError(code: "arguments_missing", message: "eventChannelName cannot be null", details: nil))
                return ;
            }

            let eventChannelName = args["eventChannelName"] as! String
            let message = args["body"] as! String
            let socketClient = self.openChannelsDicionary[eventChannelName]
            os_log("sendMessage called in eventChannelName: %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info, String(describing: eventChannelName))

            if(socketClient != nil){
                socketClient!.send(message: message)
                result(true)
            }
            else{
                result(false)
            }
        case "sendByteData":
            let args = call.arguments as! NSDictionary
            guard args["eventChannelName"] != nil else{
                result(FlutterError(code: "arguments_missing", message: "eventChannelName cannot be null", details: nil))
                return ;
            }
            let eventChannelName = args["eventChannelName"] as! String
            let message = args["body"] as! FlutterStandardTypedData
            let socketClient = self.openChannelsDicionary[eventChannelName]
            os_log("sendByteData called in eventChannelName: %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info, String(describing: eventChannelName))

            if(socketClient != nil){
                socketClient!.send(message: message.data)
                result(true)
            }
            else{
                result(false)
            }

        default: result(FlutterError(code: "wrong_method", message: "wrong method name", details: nil))
        }
    }

    /*
     Stream handler for websocket event channel

     */
    class WebSocketStreamHandler: NSObject, FlutterStreamHandler{
        let socketClient: AirWatchWorkaroundWebSocketClient?;
        var channelName: String!;
        var openChannelsDicionary: SharedDictionary<String, AirWatchWorkaroundWebSocketClient>
        var eventSink: FlutterEventSink?;
        var url: String!;
        init(channelName: String!, openChannelsDicionary: SharedDictionary<String, AirWatchWorkaroundWebSocketClient>, url: String!) throws {
            self.channelName = channelName
            self.openChannelsDicionary = openChannelsDicionary
            self.url = url
            self.socketClient = AirWatchWorkaroundWebSocketClient(url: URL(string: url)!)
        }

        /*
         Called from flutter when a client wants to listen to a socket
         */
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {


            let args = arguments as? NSDictionary
            //URL should not be passed
            guard args?["url"] as? String == nil else {
                return FlutterError(code: "1", message: "arguments.url should not be used here, since it's passed in createAndGetEventChannelName method", details: nil)
            }
            //            guard args["headers"] as? String != nil else {
            //                return FlutterError(code: "1", message: "arguments.header cannot be null and must be a string!", details: nil)
            //            }

            //            let headers = args["headers"] as! String


            os_log("onListen called with url: %@",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info, String(describing: self.url!))


            openChannelsDicionary[channelName] = socketClient
            socketClient!.receive(eventSink: events)
            self.eventSink = events




            return nil

        }

        /*
         CALLED FROM FLUTTER EVENT CHANNEL
         Disconnects from socket and removes entry from openChannelsDicionary
         */
        func onCancel(withArguments arguments: Any?) -> FlutterError? {

            // disconnect from websocket
            socketClient!.close()
            self.openChannelsDicionary.dict.removeValue(forKey: self.channelName)
            return nil
        }

        func webSocketChannelNameMethodHandler(call: FlutterMethodCall, result: @escaping FlutterResult){

            guard call.method == "send" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let args = call.arguments as! NSDictionary
            os_log("WebSocketStreamHandler.send called",log: OSLog.airWatchWorkaroundHttpClient,type: .info)


            guard args["body"] as? String != nil else {
                os_log("WebSocketStreamHandler.send called without body argument. FlutterError will be returned",log: OSLog.airWatchWorkaroundHttpClient,type: .error)
                result(FlutterError(code: "1", message: "arguments.url cannot be null and must be a string!", details: nil))
                return
            }
            let body: String = args["body"] as! String


            if(socketClient == nil || socketClient!.isClosed()){
                os_log("WebSocketStreamHandler.send called to an already closed socket",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
                result(FlutterMethodNotImplemented)
                result(FlutterError(code: "no_socket_client ", message: "there is no socket client... maybe yet", details: nil))
            }
            else{
                socketClient?.send(message: body)
                result(true)
            }



        }
    }

    /*
     Socket client, build for an URL
     Send method just supports string for now
     Error codes:

        Receive
            code: "0x01", message: "Message from WebSocket was not string nor binary"
            code: "0x02", message: "Failure while listening to data from remote socket"

     */
    class AirWatchWorkaroundWebSocketClient: NSObject{

        var webSocketTask: URLSessionWebSocketTask
        var delegate: AirWatchWorkaroundSessionDelegate = AirWatchWorkaroundSessionDelegate()
        init(url: URL) {
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())
            self.webSocketTask = session.webSocketTask(with: url)
            webSocketTask.resume()
        }
        func ping(){

            os_log("AirWatchWorkaroundWebSocketClient.ping called ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .debug)

            webSocketTask.sendPing { error in
                if let error = error {
                    os_log("Error when sending PING: %@ ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error, String(describing: error))
                }
            }
        }
        func close() {
            os_log("AirWatchWorkaroundWebSocketClient.close: Web Socket connection close requested ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
            let reason = "Closing connection".data(using: .utf8)
            webSocketTask.cancel(with: .goingAway, reason: reason)


        }
        func isClosed () -> Bool{ return self.webSocketTask.closeCode.rawValue > 0}

        func send(message: String!) {
            os_log("AirWatchWorkaroundWebSocketClient.send requested ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .debug)
            self.webSocketTask.send(.string(message)) { error in
                if let error = error {
                    os_log("AirWatchWorkaroundWebSocketClient.send: Error trying to send a message %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                }
            }
        }
        func send(message: Data){
            os_log("AirWatchWorkaroundWebSocketClient.send requested ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .debug)
            self.webSocketTask.send(.data(message)) { error in
                if let error = error {
                    os_log("AirWatchWorkaroundWebSocketClient.send: Error trying to send a message %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                }
            }
        }
        func receive(eventSink events: @escaping FlutterEventSink) {
            webSocketTask.receive{ result in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                            os_log("received message, type data with content: %@",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info, String(describing:data ))
                            events(data)
                        case .string(let text):
                            os_log("received message, type string with content: %@",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info, String(describing:text ))
                            events(text)
                        @unknown default:
                            events(FlutterError(code: "0x01", message: "Received message from WebSocket was not string nor binary", details: nil))
                    }
                    self.receive(eventSink: events)
                case .failure(let error):
                    os_log("receive: error result from receive %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                    events(FlutterError(code: "0x02", message: "Failure while listening to data from remote socket", details: error.localizedDescription))

                }



            }
        }

    }


}





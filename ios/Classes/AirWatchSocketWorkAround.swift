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
    var openChannelsDictionary:SharedDictionary = SharedDictionary<String, AirWatchWorkaroundWebSocketClient>()
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


    /// Flutter Method call handler
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
                result(FlutterError(code: AirWatchSocketWorkAroundErrors.illegalArguments, message: "url cannot be null", details: nil))
                return ;
            }
            let url = args["url"] as! String
            // appends webSocketChannelName with the current timestamp
            let newEventChannelName = "\(AirWatchSocketWorkAround.webSocketChannelName)_\(NSDate().timeIntervalSince1970)";
            os_log("createAndGetEventChannelName: creating a newEventChannelName %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .debug, String(describing: newEventChannelName))

            do{
                os_log("createAndGetEventChannelName: before creating WebSocketStreamHandler",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info)
                /// TODO Since this handler is not closable, is the execution capable of realsing resources in GC ?
                let streamHandler =  try WebSocketStreamHandler(channelName: newEventChannelName, openChannelsDictionary: openChannelsDictionary, url: url)
                //websocket event channel
                let eventChannel = FlutterEventChannel(name: newEventChannelName, binaryMessenger: messenger)
                eventChannel.setStreamHandler(streamHandler)

                os_log("createAndGetEventChannelName: returning newEventChannelName %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info, String(describing: newEventChannelName))
                result("\(newEventChannelName)")
                
                /// Socket close Chaos monkey
                /*
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { // Change `2.0` to the desired number of seconds.
                    os_log("chaos monkey triggered ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error)
                    streamHandler.onCancel(withArguments: URLSessionWebSocketTask.CloseCode.goingAway)
                */

            }
            catch{
                os_log("Error when creating WebSocketStreamHandler %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                result("Error when creating WebSocketStreamHandler: \(error)")
            }

        case "sendMessage":
            let args = call.arguments as! NSDictionary
            guard args["eventChannelName"] != nil else{
                result(FlutterError(code: AirWatchSocketWorkAroundErrors.illegalArguments, message: "eventChannelName cannot be null", details: nil))
                return ;
            }

            let eventChannelName = args["eventChannelName"] as! String
            let message = args["body"] as! String
            let socketClient = self.openChannelsDictionary[eventChannelName]
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
                result(FlutterError(code: AirWatchSocketWorkAroundErrors.illegalArguments, message: "eventChannelName cannot be null", details: nil))
                return ;
            }
            let eventChannelName = args["eventChannelName"] as! String
            let message = args["body"] as! FlutterStandardTypedData
            let socketClient = self.openChannelsDictionary[eventChannelName]
            os_log("sendByteData called in eventChannelName: %@",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info, String(describing: eventChannelName))

            if(socketClient != nil){
                socketClient!.send(message: message.data)
                result(true)
            }
            else{
                result(false)
            }

        default: result(FlutterError(code: AirWatchSocketWorkAroundErrors.illegalArguments, message: "wrong method name", details: nil))
        }
    }

    /*
     Stream handler for websocket event channel

     */
    class WebSocketStreamHandler: NSObject, FlutterStreamHandler{
        let socketClient: AirWatchWorkaroundWebSocketClient?
        var channelName: String!
        var openChannelsDictionary: SharedDictionary<String, AirWatchWorkaroundWebSocketClient>
        var eventSink: FlutterEventSink?
        var url: String!
        init(channelName: String!, openChannelsDictionary: SharedDictionary<String, AirWatchWorkaroundWebSocketClient>, url: String!) throws {
            self.channelName = channelName
            self.openChannelsDictionary = openChannelsDictionary
            self.url = url
            self.socketClient = AirWatchWorkaroundWebSocketClient(url: URL(string: url)!)
        }

        /// Called from flutter when a client wants to listen to a socket
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {


            let args = arguments as? NSDictionary
            // URL should not be passed
            guard args?["url"] as? String == nil else {
                return FlutterError(code: AirWatchSocketWorkAroundErrors.illegalArguments, message: "arguments.url should not be used here, since it's passed in createAndGetEventChannelName method", details: nil)
            }
            os_log("onListen called with url: %@ and channel name %@",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info, String(describing: self.url!), String(describing: self.channelName))

            if openChannelsDictionary[channelName] != nil{
                openChannelsDictionary[channelName]?.close(withCode: URLSessionWebSocketTask.CloseCode.abnormalClosure, reason: nil)
                os_log("WE ALREADY HAVE A socketClient FOR THIS CHANNEL. TODO IMPROVE and maybe reuse?! %@",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info, String(describing: channelName))
            }
            openChannelsDictionary[channelName] = socketClient
            socketClient!.receive(eventSink: events)
            socketClient!.runScavenger()
            self.eventSink = events
            return nil
        }

        /*
         CALLED FROM FLUTTER EVENT CHANNEL
         Disconnects from socket and removes entry from openChannelsDictionary
         */
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            os_log("==> Client called ( flutter ) cancel <== ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .debug)
            // disconnect from websocket
            socketClient!.close(withCode: .goingAway,reason: nil);
            self.openChannelsDictionary.dict.removeValue(forKey: self.channelName)
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
                result(FlutterError(code:AirWatchSocketWorkAroundErrors.illegalArguments, message: "arguments.url cannot be null and must be a string!", details: nil))
                return
            }
            let body: String = args["body"] as! String


            if(socketClient == nil || socketClient!.isClosed()){
                os_log("WebSocketStreamHandler.send called to an already closed socket",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
                result(FlutterMethodNotImplemented)
                                result(FlutterError(code: AirWatchSocketWorkAroundErrors.noSocketOrSocketClosed, message: "there is no socket client... maybe yet", details: nil))
            }
            else{
                socketClient?.send(message: body)
                result(true)
            }



        }
    }

    /**
    Error codes:

       Receive
           code: "unknownContentTypeFromServerMessage", message: "Message from WebSocket was not string nor binary"
           code: "failureReceivingMessageFromSocket", message: "Failure while listening to data from remote socket"
    */
    class AirWatchSocketWorkAroundErrors{
        static let unknownContentTypeFromServerMessage: String = "unknownContentTypeFromServerMessage";
        static let failureReceivingMessageFromSocket: String = "failureReceivingMessageFromSocket";
        static let illegalArguments: String = "illegalArguments";
        static let noSocketOrSocketClosed: String = "noSocketOrSocketClosed";
    }
    /*
     Socket client, build for an URL
     Send method just supports string for now
     */
    class AirWatchWorkaroundWebSocketClient: NSObject{

        var webSocketTask: URLSessionWebSocketTask
        var delegate: AirWatchWorkaroundSessionDelegate = AirWatchWorkaroundSessionDelegate()
        let session:URLSession;
        var flutterEventSink: FlutterEventSink? ;
        init(url: URL) {
            session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())
            self.webSocketTask = session.webSocketTask(with: url)
            webSocketTask.resume()
        }
        /// Finds and calls _onClose on airWatchWorkaroundWebSocketClient instances that have a
        /// closed URLSessionWebSocketTask
        func runScavenger(){

         // every 5 seconds, check if the socket is stil open
         DispatchQueue.main.asyncAfter(deadline: .now() + 5){
             let closed: Bool = self.isClosed()
             os_log("airWatchWorkaroundWebSocketClient.healthCheckTask: isClosed %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .debug, String(describing: closed))
             if(closed){
                 os_log("airWatchWorkaroundWebSocketClient.healthCheckTask: canceling task ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .info)
                 self._onClose();
             }
             else{
                 self.runScavenger();
             }

         }
        }
        func ping(){

            os_log("AirWatchWorkaroundWebSocketClient.ping called ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .debug)

            webSocketTask.sendPing { error in
                if let error = error {
                    os_log("Error when sending PING: %@ ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error, String(describing: error))
                }
            }
        }
        /// triggers closed of the websocketTask
        func close(withCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            os_log("airWatchWorkaroundWebSocketClient.close: Web Socket connection close requested ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
            webSocketTask.cancel(with: withCode, reason: reason)
            _onClose();

        }

        /// this should be private...
        func _onClose(){
            if(self.flutterEventSink == nil){
                os_log("==> the socket was closed but i have no sink to inform flutter abourt it !!! <== ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
            }
            else{
                self.flutterEventSink!(FlutterError(code: AirWatchSocketWorkAroundErrors.noSocketOrSocketClosed, message: "Socket has been closed!",details: ""))
            }
            session.invalidateAndCancel()

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
            self.flutterEventSink = events;
            
            delegate.setOnWebSocketClose(onWebSocketCloseHandler: {
                os_log("=====> onWebSocketCloseHandler <=====",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info)
                self._onClose();
            });
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
                            events(FlutterError(code: AirWatchSocketWorkAroundErrors.unknownContentTypeFromServerMessage, message: "Received message from WebSocket was not string nor binary", details: nil))
                    }
                    self.receive(eventSink: events)
                case .failure(let error):
                    os_log("receive: error result from receive %@ ",log: OSLog.airWatchWorkaroundWebSocketClient, type: .error, String(describing: error))
                    events(FlutterError(code: AirWatchSocketWorkAroundErrors.failureReceivingMessageFromSocket, message: "Failure while listening to data from remote socket", details: error.localizedDescription))

                }



            }
        }

    }


}





import Flutter
import UIKit
import os
public class SwiftAirwatchSocketWorkaroundPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    AirWatchSocketWorkAround.register(with: registrar);
    AirWatchHttpWorkAround.register(with: registrar);
  }
 }

  /*
   Swift doesn't chare dictionaries by reference, always by copy
   */
  class SharedDictionary<K : Hashable, V> {
      var dict : Dictionary<K, V> = Dictionary()
      subscript(key : K) -> V? {
          get {
              return dict[key]
          }
          set(newValue) {
              dict[key] = newValue
          }
      }
  }


  extension OSLog {
      private static var subsystem = Bundle.main.bundleIdentifier!

      /// Logs the view cycles like viewDidLoad.
      static let airWatchWorkaroundHttpClient = OSLog(subsystem: subsystem, category: "airWatchWorkaroundHttpClient")
      static let airWatchWorkaroundWebSocketClient = OSLog(subsystem: subsystem, category: "airWatchWorkaroundWebSocketClient")
  }

  class AirWatchWorkaroundSessionDelegate: NSObject, URLSessionDelegate, URLSessionWebSocketDelegate {

        // URLSessionWebSocketTask doesn't seem to be able to tell if the it's closed or not....
        var onWebSocketCloseHandler: (() -> ())?;
        
        func setOnWebSocketClose(onWebSocketCloseHandler: (()-> ())? ) {
            self.onWebSocketCloseHandler = onWebSocketCloseHandler;
        }

      /*
       This method implemenents urlSession from URLSessionDelegate
       The goal is to bypass certification check
       This is specially revelevant using IOS Simulator
       */
      func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
          completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
      }

      /*
       Specialized urlSession for websocket connect event
       */
      func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
          os_log(" ===> socket connected <==== ",log: OSLog.airWatchWorkaroundWebSocketClient ,type: .error)
          

      }

      /*
       Specialized urlSession for websocket disconnect event
       */
      func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
          os_log(" ===> INFO socket disconnected from server side <==== ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .info)
          os_log(" ===> socket disconnected from server side <==== ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error)
        
        if(onWebSocketCloseHandler != nil){
                    onWebSocketCloseHandler!();
        }
        else{
            os_log(" ===>  socket disconnected BUT NO onWebSocketCloseHandler defined!!! <==== ",log: OSLog.airWatchWorkaroundWebSocketClient,type: .error);
        }

      }

      
  }





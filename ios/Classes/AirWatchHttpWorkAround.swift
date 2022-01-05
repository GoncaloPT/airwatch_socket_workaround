//
//  AirWatchHttpWorkAround.swift
//  Runner
//
//  Created by Gonçalo Silva on 05/03/2021.
//
//  The goal of this class is to provide a TEMPORARY workaround that allows the usage
//  of htto requests communicate with VPN protected domains, which are currently inside closed network.
//  Therefore, to access them, perAppVpn is used. Per app vpn is not working when the request
//  is originated from DART VM.
//  Issues:
//        DART => https://github.com/dart-lang/sdk/issues/41376
//        FLutter => https://github.com/flutter/flutter/issues/41500
//  Once this issues are solved, or the backend moves to a public hosted cloud, this class should be deprecated!
//

import Flutter
import UIKit
import os

public class AirWatchHttpWorkAround: NSObject {

    static let httpChannelName = "org.goncalopt.airWatchSocketWorkAround/http"

    // builder method for AirWatchHttpWorkAround
    public static func register(with registrar: FlutterPluginRegistrar) {
        os_log("AirWatchHttpWorkAround.register called. Please make sure this is still needed, since it's a workaround!! ",log: OSLog.airWatchWorkaroundHttpClient,type: .info)

        let airWatchHttpWorkAround = AirWatchHttpWorkAround()
        let httpChannel = FlutterMethodChannel(name: httpChannelName,
                                               binaryMessenger: registrar.messenger())

        httpChannel.setMethodCallHandler(airWatchHttpWorkAround.handle)

    }

    /// Flutter MethodCallHandler
    /// This method supports various types of request data.
    /// The support is provided based on the content-type header.
    /// For each "know" content-type, a instance of [HttpRequestData] implementaion is provided by [HttpRequestDataFactory]
    func handle(call: FlutterMethodCall, result: @escaping FlutterResult){
        guard call.method == "doRequest"
        else {
            result(FlutterMethodNotImplemented)
            return
        }

        let args = call.arguments as! NSDictionary
        os_log("handle called with arguments: %@",log: OSLog.airWatchWorkaroundHttpClient,type: .debug, String(describing: args))
        let factory: HttpRequestDataFactory = HttpRequestDataFactory.init()

        do{
            let httpRequestData = try factory.build(args: args)
            doRequest(data: httpRequestData, result: result)
        } catch let error as InvalidArgumentsError{
            result(FlutterError(code: "arguments_missing", message: error.rawValue, details: nil))
        } catch let error as NSError{
            result(FlutterError(code: "unkown error", message: error.description, details: nil))
        }
    }


    func doRequest(data: HttpRequestData, result: @escaping FlutterResult){

        let session = URLSession(configuration: .default, delegate: AirWatchWorkaroundSessionDelegate(),delegateQueue: nil);
        os_log("doRquest called with url: %@ for method %@  ",log: OSLog.airWatchWorkaroundHttpClient,type: .info, String(describing: data.url), String(describing: method))
        var request = URLRequest(url: URL(string: data.url)!)
        for header in data.headers{
            let value = header.value as! String
            let key = header.key as! String
            request.setValue(value, forHTTPHeaderField: key)
            os_log("doRquest adding header: %@:%d ",log: OSLog.airWatchWorkaroundHttpClient,type: .debug, String(describing: key) , String(describing: value))
        }
        request.httpMethod = data.method
        request.httpBody = data.getBody()

        let task = session.dataTask(with: request) { data, response, error in
            if(error != nil || data == nil){
                os_log("request done. Error occured %@ ",log: OSLog.airWatchWorkaroundHttpClient,type: .error, String(describing: error) )

                result([
                    "statusCode": (response as? HTTPURLResponse)?.statusCode
                ]);
            }
            else{
                result([
                    "data": NSString(data: data!, encoding: String.Encoding.utf8.rawValue),
                    "statusCode": (response as? HTTPURLResponse)?.statusCode,
                    "headers": (response as? HTTPURLResponse)?.allHeaderFields as NSDictionary? as! [String:String]?
                ]);
            }


        }
        task.resume()
    }
}

/// Interface for HttpResqueData
protocol HttpRequestData {
    var url: String! { get set }
    var headers : NSDictionary! { get set }
    var method : String! { get set }
    /// Factory funcion
    static func buildFromArguments(args: NSDictionary!) throws -> HttpRequestData
    /// Converts the body to the needed format for the request, which is instance of [Data]
    func getBody() -> Data?
}
/// [HttpRequestData] implementation that assumes a multipart request
/// For more information related to mapping between flutter method channel arguments and this class,
/// PLease see buildFromArguments method documentation

class MultiPartHttpRequest : HttpRequestData{
   

    // body {
    // "MultiPartEntry" {
    // contentType": String, "name": String, "data":  FlutterStandardTypedData}
    // }
    // }

    var url: String!
    var headers: NSDictionary!
    var method: String!
    var bodyParts: [BodyPart]!

    init(url: String!, headers: NSDictionary!, method: String!, bodyParts: [BodyPart]!){
        self.url = url
        self.headers = headers
        self.method = method
        self.bodyParts = bodyParts
    }

    /// Adapter method for FlutterMethodChannel arguments
    /// Assuming structure :
    /// {
    ///     "url": String
    ///     "headers": {
    ///     ....
    ///     }
    ///     "url": String
    ///     "body": [
    ///         {
    ///             "name": String
    ///             "data": FlutterStandardTypedData
    ///             "contentType": String
    ///         }
    ///     ]
    ///
    ///     }
    /// }
    static func buildFromArguments(args: NSDictionary!) throws -> HttpRequestData {

        os_log("buildFromArguments: body is %@",log: OSLog.airWatchWorkaroundHttpClient,type: .info,String(describing: args["body"]) )
        let url = args["url"] as? String
        let headers = args["headers"] as! NSDictionary
        let method = args["method"] as? String
        let body = args["body"] as? [[String: Any]]

        os_log("buildFromArguments: body is %@",log: OSLog.airWatchWorkaroundHttpClient,type: .info,String(describing: body ))
        if(url == nil){
            throw InvalidArgumentsError.noURL;
        }
        if(method == nil){
            throw InvalidArgumentsError.noMethod;
        }
        if(body == nil){
            throw InvalidArgumentsError.noBody;
        }
        var bodyParts = [BodyPart]()
        for dictEntry in body!{
            bodyParts.append(BodyPart.fromFlutterMethodChannelBodyEntry(multiPartEntry: dictEntry))
        }
        return MultiPartHttpRequest(url: url, headers: headers, method: method, bodyParts: bodyParts)
    }

    /// Adaptes the content of the body to [Data]
    func getBody() -> Data? {
        var formParts = [MultipartForm.Part]()
        for bodyPart in bodyParts {
            formParts.append(MultipartForm.Part(name: bodyPart.name, data: bodyPart.data, contentType: bodyPart.contentType))
        }
        let form = MultipartForm(parts: formParts)
        return form.bodyData;
    }

    public struct BodyPart: Hashable, Equatable {
        public var name: String
        public var data: Data
        public var contentType: String?

        /// Adapter method for FlutterMethodChannel arguments
        /// Assuming structure :

        ///         {
        ///             "name": String
        ///             "data": FlutterStandardTypedData
        ///             "contentType": String
        ///         }
        public static func fromFlutterMethodChannelBodyEntry(multiPartEntry: [String: Any]!) -> BodyPart {
            return BodyPart(name: multiPartEntry["name"] as! String,
                            data: (multiPartEntry["data"] as! String).data(using: .utf8)!,
                                      contentType: multiPartEntry["contentType"] as? String);
        }
    }
}

/// SingleBody in absence of a better name... it just means its not multipart = has one body
/// SingleBodyStringHttpRequest assumes a String body
class SingleBodyStringHttpRequest: HttpRequestData{
    var url: String!
    var headers: NSDictionary!
    var method: String!
    var body: String!
    init(url: String!, headers: NSDictionary!, method: String!, body: String!){
        self.url = url
        self.headers = headers
        self.method = method
        self.body = body
    }

    static func buildFromArguments(args: NSDictionary!) throws -> HttpRequestData {
        let url = args["url"] as? String
        let headers = args["headers"] as? NSDictionary
        let method = args["method"] as? String
        let body = args["body"] as? String
        if(url == nil){
            throw InvalidArgumentsError.noURL;
        }
        if(method == nil){
            throw InvalidArgumentsError.noMethod;
        }
        return SingleBodyStringHttpRequest(url: url, headers: headers, method: method, body: body)
    }
    func getBody() -> Data? {
        return body?.data(using: .utf8)
    }
}
public enum InvalidArgumentsError: String,Error{
    case noURL = "Please provide URL in call arguments.";
    case noMethod = "Please provide method in call arguments.";
    case noBody = "Please provide a body in call arguments.";
}


/// SingleBody in absence of a better name... it just means its not multipart = has one body
/// SingleBodyRawHttpRequest assumes a body of byte[]
class SingleBodyRawHttpRequest: HttpRequestData{
    var url: String!
    var headers: NSDictionary!
    var method: String!
    var bodyBytes : FlutterStandardTypedData!
    init(url: String!, headers: NSDictionary!, method: String!, bodyBytes: FlutterStandardTypedData!){
        self.url = url
        self.headers = headers
        self.method = method
        self.bodyBytes = bodyBytes
    }

    static func buildFromArguments(args: NSDictionary!) throws -> HttpRequestData {
        let url = args["url"] as? String
        let headers = args["headers"] as! NSDictionary
        let method = args["method"] as? String
        let bodyBytes = args["body"] as? FlutterStandardTypedData
        if(url == nil){
            throw InvalidArgumentsError.noURL;
        }
        if(method == nil){
            throw InvalidArgumentsError.noMethod;
        }

        return SingleBodyRawHttpRequest(url: url, headers: headers, method: method, bodyBytes: bodyBytes)
    }

    func getBody() -> Data? {
        return bodyBytes?.data
    }

}


/// Factory for [HttpRequestData] instances
/// Current implemention uses content-type header to infer what is the right [HttpRequestData] instance
class HttpRequestDataFactory{
    func build(args: NSDictionary!) throws -> HttpRequestData   {
        let headers = args["headers"] as! NSDictionary
        let contentTypeHeader = (headers["content-type"] as? String) ?? (headers["Content-Type"] as? String);
        // for byte array body
        os_log("HttpRequestDataFactory: build HttpRequestData for contentType %@",log: OSLog.airWatchWorkaroundHttpClient,type: .info,  String(describing: contentTypeHeader))
        if( contentTypeHeader != nil && contentTypeHeader!.contains("application/json")){
            os_log("HttpRequestDataFactory: returning SingleBodyStringHttpRequest",log: OSLog.airWatchWorkaroundHttpClient,type: .info)
            return try SingleBodyStringHttpRequest.buildFromArguments(args: args)
        }
//        else if (  contentTypeHeader != nil && contentTypeHeader!.contains("multipart/form-data")){
//            os_log("HttpRequestDataFactory: returning MultiPartHttpRequest",log: OSLog.airWatchWorkaroundHttpClient,type: .info)
//            return try MultiPartHttpRequest.buildFromArguments(args: args)
//        }
        os_log("HttpRequestDataFactory: returning SingleBodyRawHttpRequest",log: OSLog.airWatchWorkaroundHttpClient,type: .info)
        return try SingleBodyRawHttpRequest.buildFromArguments(args: args)
        
    }
}




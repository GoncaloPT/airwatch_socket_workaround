# airwatch_socket_workaround

This plugin has been created to enable flutter apps to reach endpoints that are only reachable using a VMWare airwatch per app vpn.  

## Current status
In development  
## TODO
- <s>provide simple example using custom HttpClient</s>
- prepare for publishing
- add examples for websocket 
- add example for multipart post
- provide HLD

## Getting started

### Example
Example provides 3 basic use cases:
- HTTP GET
- Websocket (WIP)
- HTTP Post multipart (WIP)

#### Http requests
Http requests can be sent using the 'native' socket by using AirWatchHttpWorkAround.
doRequest method receives a dart http [Request](https://pub.dev/documentation/http/latest/http/Request-class.html ) which is part of dart [http package](https://pub.dev/documentation/http/latest/)
and handover the request to the native part of the plugin. 

Example:
```dart
Future<String> get(String endpoint) {
  var request = Request('GET', Uri.parse(endpoint));
  return AirWatchWorkAroundFactory.getInstance().doRequest(request);  
}

```

## Why is this needed?   
Because Flutter(dart actually) currently is not respecting system "proxy" and therefore
per APN VPN solutions, like vmware AirWatch do not work.
Therefore, this class should only be used in IOS Plugin based Network client

The responsibility of using only in IOS is not enforced in any way by this class, it is delegated to plugin users.


## Other considerations
### Why not fetching system proxy?
Trying to get the current system proxy DO NOT WORK, since the system proxy is always null.

### Is there already a bug for this?
An issue exists in flutter: https://github.com/flutter/flutter/issues/41500



# airwatch_socket_workaround

This plugin has been created to enable flutter apps to reach endpoints that are only reachable using a VMWare airwatch per app vpn.  

## Current status
In development  
## TODO
- provide simple Service example using custom HttpClient 
- add examples for websocket 
- add example for multipart post
- prepare for publishing
## How to use it?
Example provides 3 basic use cases:
- HTTP GET
- Websocket
- HTTP Post multipart
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



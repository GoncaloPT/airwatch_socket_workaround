#import "AirwatchSocketWorkaroundPlugin.h"
#if __has_include(<airwatch_socket_workaround/airwatch_socket_workaround-Swift.h>)
#import <airwatch_socket_workaround/airwatch_socket_workaround-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "airwatch_socket_workaround-Swift.h"
#endif

@implementation AirwatchSocketWorkaroundPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAirwatchSocketWorkaroundPlugin registerWithRegistrar:registrar];
}
@end

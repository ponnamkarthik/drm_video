#import "DrmVideoPlugin.h"
#if __has_include(<drm_video/drm_video-Swift.h>)
#import <drm_video/drm_video-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "drm_video-Swift.h"
#endif

@implementation DrmVideoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDrmVideoPlugin registerWithRegistrar:registrar];
}
@end

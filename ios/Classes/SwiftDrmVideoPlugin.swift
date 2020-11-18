import Flutter
import UIKit

//public class SwiftDrmVideoPlugin: NSObject, FlutterPlugin {
//  public static func register(with registrar: FlutterPluginRegistrar) {
//    let channel = FlutterMethodChannel(name: "drm_video", binaryMessenger: registrar.messenger())
//    let instance = SwiftDrmVideoPlugin()
//    registrar.addMethodCallDelegate(instance, channel: channel)
//  }
//
//  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//    result("iOS " + UIDevice.current.systemVersion)
//  }
//}

public class SwiftDrmVideoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = SwiftDrmVideoFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "drmvideo")
    }
}

//
//  DrmVideoFactory.swift
//  drm_video
//
//  Created by Karthik Ponnam on 15/11/20.
//

import Flutter
import UIKit

class SwiftDrmVideoFactory: NSObject, FlutterPlatformViewFactory {
    private weak var messenger: FlutterBinaryMessenger?

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        self.messenger = messenger
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return SwiftDrmVideoView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

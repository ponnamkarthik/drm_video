//
//  DrmVideoView.swift
//  drm_video
//
//  Created by Karthik Ponnam on 15/11/20.
//
import Flutter
import UIKit
import AVFoundation

class SwiftDrmVideoView: NSObject, FlutterPlatformView, FlutterStreamHandler {
    private var _view: UIView
    private var eventSink: FlutterEventSink?
    
    private var player: AVPlayer
    private var channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    
    private var isInitialized: Bool = false
    private var isLooping: Bool = false
    private var isPlaying: Bool = false
    private var disposed: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
        }
        _view = UIView()
        
        self.channel = FlutterMethodChannel(name: "drmvideo_\(viewId)", binaryMessenger: messenger!)
        self.eventChannel = FlutterEventChannel(name: "drmvideo_events\(viewId)", binaryMessenger: messenger!)
        
        
        let videoURL = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")
        player = AVPlayer(url: videoURL!)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self._view.bounds
        self._view.layer.addSublayer(playerLayer)
        player.pause()
//        player.play()
        
        super.init()
        
        channel.setMethodCallHandler(self.handle)
        eventChannel.setStreamHandler(self)
        
        addObservers()
    }
    
    
    func addObservers() {
        player.currentItem!.addObserver(
            self,
            forKeyPath: "loadedTimeRanges",
            options: [.initial, .new],
            context: nil)
        player.currentItem!.addObserver(
            self,
            forKeyPath: "status",
            options: [.initial, .new],
            context: nil)
        player.currentItem!.addObserver(
            self,
            forKeyPath: "playbackLikelyToKeepUp",
            options: [.initial, .new],
            context: nil)
        player.currentItem!.addObserver(
            self,
            forKeyPath: "playbackBufferEmpty",
            options: [.initial, .new],
            context: nil)
        player.currentItem!.addObserver(
            self,
            forKeyPath: "playbackBufferFull",
            options: [.initial, .new],
            context: nil)

        // Add an observer that will respond to itemDidPlayToEndTime
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidPlay(toEndTime:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player)
    }
    
    @objc private func itemDidPlay(toEndTime notification: Notification?) {
        if isLooping {
            let p = notification?.object as? AVPlayerItem
            p?.seek(to: .zero, completionHandler: nil)
        } else {
            if (eventSink != nil) {
                eventSink!([
                    "event": "completed"
                ])
            }
        }
    }
    
    func updatePlayingState() {
        if !isInitialized {
            return
        }
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
    }
    
    public func failedVideo(_ item: AVPlayerItem?) {
        if eventSink != nil {
            eventSink!(
                FlutterError(
                    code: "VideoError",
                    message: "Failed to load video: " + (item?.error?.localizedDescription ?? ""),
                    details: nil))
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            if eventSink != nil {
                var values: [[NSNumber]]? = []
                for rangeValue in (object as AnyObject).loadedTimeRanges ?? [] {
                    let range = rangeValue.timeRangeValue
                    let start = TimeToMillis(range.start)
                    values?.append([NSNumber(value: start), NSNumber(value: start + TimeToMillis(range.duration))])
                }
                if let values = values {
                    eventSink!([
                        "event": "bufferingUpdate",
                        "values": values
                    ])
                }
            }
        } else if keyPath == "status" {
            let item = object as? AVPlayerItem
            switch item?.status {
                case .failed:
                    self.failedVideo(item)
                case .readyToPlay:
                    self.sendInitialized()
                    self.updatePlayingState()
                case .unknown:
                    break
                @unknown default:
                    break
            }
        } else if keyPath == "playbackLikelyToKeepUp" {
            if player.currentItem?.isPlaybackLikelyToKeepUp ?? false {
                updatePlayingState()
                if eventSink != nil {
                    eventSink!([
                        "event": "bufferingEnd"
                    ])
                }
            }
        } else if keyPath == "playbackBufferEmpty" {
            if eventSink != nil {
                eventSink!([
                    "event": "bufferingStart"
                ])
            }
        } else if keyPath == "playbackBufferFull" {
            if eventSink != nil {
                eventSink!([
                    "event": "bufferingEnd"
                ])
            }
        }
    }
    
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        sendInitialized()
      return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
      return nil
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "play":
                self.play()
            case "pause":
                self.pause()
            case "seekTo":
                if(call.arguments != nil) {
                    self.seek(to: call.arguments as! Int)
                }
            case "setVolume":
                if(call.arguments != nil) {
                    self.setVolume(call.arguments as! Double)
                }
            case "setLooping":
                if(call.arguments != nil) {
                    self.isLooping = (call.arguments as? Bool)!
                }
            case "setPlaybackSpeed":
                self.setPlaybackSpeed(call.arguments as! Double)
            case "getPosition":
                result(position())
            case "dispose":
                dispose()
            default:
                result(1)
            }
        }
    
    func play() {
        self.player.play()
    }
    
    func pause() {
        self.player.pause();
    }

    func view() -> UIView {
        return _view
    }
    
    func sendInitialized() {
        if (self.eventSink != nil) && !isInitialized {
            let size = player.currentItem?.presentationSize
            let width = size?.width ?? 0.0
            let height = size?.height ?? 0.0

            // The player has not yet initialized.
            if height == CGSize.zero.height && width == CGSize.zero.width {
                return
            }
            // The player may be initialized but still needs to determine the duration.
            if duration() == 0 {
                return
            }

            isInitialized = true
            eventSink!(
                [
                            "event": "initialized",
                            "duration": NSNumber(value: duration()),
                            "width": NSNumber(value: Float(width)),
                            "height": NSNumber(value: Float(height))
                        ])
        }
    }
    
    func TimeToMillis(_ time: CMTime) -> Int64 {
        if time.timescale == 0 {
            return 0
        }
        let dur: Float64 = CMTimeGetSeconds(time);
       return Int64(1000 * dur)
    }

    
    func position() -> Int64 {
        return TimeToMillis(player.currentTime())
    }

    func duration() -> Int64 {
        return TimeToMillis(player.currentItem!.duration)
    }

    func seek(to location: Int) {
        player.seek(
            to: CMTimeMake(value: Int64(location), timescale: 1000),
            toleranceBefore: .zero,
            toleranceAfter: .zero)
    }

    func setIsLooping(_ isLooping: Bool) {
        self.isLooping = isLooping
    }

    func setVolume(_ volume: Double) {
        player.volume = Float((volume < 0.0) ? 0.0 : ((volume > 1.0) ? 1.0 : volume))
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        // See https://developer.apple.com/library/archive/qa/qa1772/_index.html for an explanation of
        // these checks.
        if speed > 2.0 && !(player.currentItem?.canPlayFastForward ?? false) {
            if eventSink != nil {
                eventSink!(
                    FlutterError(
                                    code: "VideoError",
                                    message: "Video cannot be fast-forwarded beyond 2.0x",
                                    details: nil))
            }
            return
        }

        if speed < 1.0 && !(player.currentItem?.canPlaySlowForward ?? false) {
            if eventSink != nil {
                eventSink!(
                    FlutterError(
                                    code: "VideoError",
                                    message: "Video cannot be slow-forwarded",
                                    details: nil))
            }
            return
        }

        player.rate = Float(speed)
    }
    
    func disposeSansEventChannel() {
        disposed = true
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: nil)
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "loadedTimeRanges",
            context: nil)
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "playbackLikelyToKeepUp",
            context: nil)
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "playbackBufferEmpty",
            context: nil)
        player.currentItem?.removeObserver(
            self,
            forKeyPath: "playbackBufferFull",
            context: nil)
        player.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    func dispose() {
        disposeSansEventChannel()
        eventChannel.setStreamHandler(nil)
    }
    
}

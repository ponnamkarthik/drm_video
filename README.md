# [drm_video](https://pub.dartlang.org/packages/drm_video)

### Video Player for DRM and non DRM content with every functionality provided official video_player

[![pub package](https://img.shields.io/pub/v/drm_video.svg)](https://pub.dartlang.org/packages/drm_video)

# NOTICE

> This Plugin uses some code from [video_player](https://pub.dartlang.org/packages/video_player) plugins which is the official video_player plugin

## Installation

First, add `drm_video` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### iOS

Warning: The video player is not functional on iOS simulators. An iOS device must be used during development/testing.

Add the following entry to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

This entry allows your app to access video files by URL.

### Android

Ensure the following permission is present in your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Example

```dart
import 'package:flutter/material.dart';
import 'package:drm_video/drm_video.dart';
import 'package:drm_video/video_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  VideoController _videoController;
  String dashUrl = "https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd";
  String licenseUrl = "https://proxy.staging.widevine.com/proxy";

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _videoController.value.isPlaying
                  ? _videoController.pause()
                  : _videoController.play();
            });
          },
          child: Icon(
            ( _videoController?.value?.isPlaying  ?? false)? Icons.pause : Icons.play_arrow,
          ),
        ),
        body: Center(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: _videoController?.value?.aspectRatio ?? 16 / 9,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Container(
                      child: DrmVideoPlayer(
                        videoUrl: dashUrl,
                        autoPlay: false,
                        drmLicenseUrl: licenseUrl,
                        onVideoControls: (VideoController controller) {
                          print("onVideoControls $controller");
                          _videoController = controller;
                          _videoController.addListener(() {
                            setState(() {});
                          });
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Working On

> DRM Support for iOS
> RTMP Support for Android

> For more code please check example project

## Buy Me a Coffee

<a href="https://www.buymeacoffee.com/karthikponnam" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drm_video/drm_video.dart';

void main() {
  const MethodChannel channel = MethodChannel('drm_video');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await DrmVideo.platformVersion, '42');
  });
}

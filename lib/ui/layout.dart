import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What the app runs on (docs/ui.md). Phones keep the portrait YouTube layout; tablets and TVs get grids, the side
/// rail and the two-column watch page on wide screens; TVs are also driven by the remote.
enum FormFactor { phone, tablet, tv }

/// Facts from the platform, read once at startup (`youpipe/system` → `device`).
class DeviceInfo {
  const DeviceInfo({this.tv = false, this.pip = true});

  /// Android TV, Google TV or Fire TV.
  final bool tv;

  /// Whether the device has picture-in-picture (most TVs don't).
  final bool pip;

  static DeviceInfo current = const DeviceInfo();

  static Future<void> load() async {
    try {
      final m = await const MethodChannel('youpipe/system').invokeMapMethod<String, Object?>('device');
      current = DeviceInfo(tv: m?['tv'] == true, pip: m?['pip'] != false);
    } on Exception catch (e) {
      debugPrint('YouPipe: device info unavailable: $e');
    }
  }
}

/// The current form factor: TV from the platform, otherwise a tablet when the shortest side is at least 600 dp.
FormFactor formFactorOf(BuildContext context) {
  if (DeviceInfo.current.tv) return FormFactor.tv;
  return MediaQuery.sizeOf(context).shortestSide >= 600 ? FormFactor.tablet : FormFactor.phone;
}

/// The form factor before the first frame (no BuildContext yet), from the first view's size.
FormFactor formFactorAtStartup() {
  if (DeviceInfo.current.tv) return FormFactor.tv;
  final view = PlatformDispatcher.instance.views.firstOrNull;
  if (view == null) return FormFactor.phone;
  final size = view.physicalSize / view.devicePixelRatio;
  return size.shortestSide >= 600 ? FormFactor.tablet : FormFactor.phone;
}

/// How many video cards fit side by side, like YouTube on tablets: 1 on phones, then 2, 3 and 4. TVs, watched from
/// the sofa like YouTube for TV, always show 4 (TVs report very different widths in dp, and more columns made the
/// thumbnails too small to read from the sofa).
int feedColumns(double width) {
  if (DeviceInfo.current.tv) return 4;
  return width < 600
      ? 1
      : width < 900
      ? 2
      : width < 1200
      ? 3
      : 4;
}

/// Wide enough for the side rail and the two-column watch page (landscape tablets, TVs).
bool isWide(Size size) => size.width >= 900 && size.width > size.height;

/// The widest a list of rows (playlist, history, settings) gets before it's centred.
const maxRowContentWidth = 840.0;

/// Orientations the app allows outside fullscreen: phones stay portrait like YouTube; tablets rotate freely; TVs
/// are left alone (an empty list means "whatever the device does").
List<DeviceOrientation> appOrientations(FormFactor f) =>
    f == FormFactor.phone ? const [DeviceOrientation.portraitUp] : const [];

/// Fullscreen: landscape either way up, following the sensor even with rotation lock on, like YouTube
/// (`youpipe/system` → `landscape`). Flutter's landscapeLeft + landscapeRight honours the lock, so it never flips.
Future<void> sensorLandscape() async {
  try {
    await const MethodChannel('youpipe/system').invokeMethod<void>('landscape');
  } on Exception catch (e) {
    debugPrint('YouPipe: sensor landscape unavailable: $e');
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }
}

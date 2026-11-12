import 'dart:ui';

import 'package:flutter/services.dart';

/// The shortest side, in logical pixels, from which a screen is a tablet's (Material's compact width ends at 600).
const double tabletShortestSide = 600;

/// The orientations the app keeps: a phone's portrait only, as it was designed, and every one on a tablet, which is held
/// either way and which iPad multitasking turns at will. A full-screen diagram or image frees them all for a while and
/// takes these back on leaving.
///
/// [size] is the screen's logical size; by default the app's own view.
List<DeviceOrientation> appOrientations([Size? size]) {
  final screen = size ?? _viewSize();
  if (screen == null || screen.shortestSide < tabletShortestSide) return const [DeviceOrientation.portraitUp];
  return const [];
}

Size? _viewSize() {
  final view = PlatformDispatcher.instance.implicitView;
  return view == null ? null : view.physicalSize / view.devicePixelRatio;
}

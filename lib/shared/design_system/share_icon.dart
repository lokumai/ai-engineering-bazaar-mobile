import 'package:flutter/material.dart';

/// The share mark each phone uses for its share sheet (plan 18.14): the box with an arrow on iOS, the three joined dots
/// on Android.
IconData shareIcon(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ? Icons.ios_share_outlined : Icons.share_outlined;

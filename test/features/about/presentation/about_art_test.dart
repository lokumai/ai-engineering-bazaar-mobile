@Tags(['unit'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/about/presentation/about_art.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each scene holds the frames its section counts, and its still and its shape match it', (tester) async {
    await tester.runAsync(() async {
      for (final (i, path) in AboutArt.scenes.indexed) {
        final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
        expect(codec.frameCount, AboutArt.frames[i], reason: path);
        final frame = (await codec.getNextFrame()).image;
        expect(frame.width / frame.height, closeTo(AboutArt.aspects[i], 0.01), reason: path);
        codec.dispose();
        final still = (await (await ui.instantiateImageCodec(
          File(AboutArt.stills[i]).readAsBytesSync(),
        )).getNextFrame()).image;
        expect((still.width, still.height), (frame.width, frame.height), reason: AboutArt.stills[i]);
      }
    });
  });
}

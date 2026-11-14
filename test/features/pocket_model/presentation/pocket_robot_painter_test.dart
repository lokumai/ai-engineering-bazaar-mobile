import 'dart:ui' as ui;

import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/presentation/pocket_robot_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _stage = Size(300, 230);

/// The box of what [painter] paints in [size], from its pixels.
Future<Rect> _painted(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
  final bytes = (await image.toByteData())!;
  var (left, top, right, bottom) = (size.width, size.height, 0.0, 0.0);
  for (var y = 0; y < size.height; y++) {
    for (var x = 0; x < size.width; x++) {
      if (bytes.getUint8((y * size.width.toInt() + x) * 4 + 3) > 40) {
        if (x < left) left = x.toDouble();
        if (x > right) right = x.toDouble();
        if (y < top) top = y.toDouble();
        if (y > bottom) bottom = y.toDouble();
      }
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

PocketRobotPainter _robot(RobotOutfit outfit) => PocketRobotPainter(
  rug: false,
  repaint: const AlwaysStoppedAnimation(0),
  frame: () => RobotFrame(
    time: 0,
    face: RobotFace.calm,
    look: Offset.zero,
    blink: 0,
    hop: 0,
    temperature: 0.8,
    level: 0,
    particles: const [],
    alive: false,
    mirrored: false,
    outfit: outfit,
  ),
);

void main() {
  test('no hat on any head reaches higher than the room for a hat', () {
    for (final head in RobotHead.values) {
      for (final hat in RobotHat.values) {
        final reach = PocketRobotPainter.hatHeight(hat) * PocketRobotPainter.hatScale(head, hat);
        expect(reach, lessThanOrEqualTo(PocketRobotPainter.hatRoom), reason: '$head $hat');
      }
    }
    expect(PocketRobotPainter.hatScale(RobotHead.classic, RobotHat.fez), 1, reason: 'the fez as it always was');
  });

  test('in a tall hat or a helmet the robot keeps its size, its hat drawn smaller, and stays in the stage', () async {
    // The robot's lower half, where no hat or glass reaches: as wide and as low in every outfit.
    Future<Rect> body(RobotOutfit outfit) async {
      final whole = await _painted(_robot(outfit), _stage);
      expect(whole.top, greaterThanOrEqualTo(0), reason: '$outfit');
      return whole;
    }

    final fez = await body(const RobotOutfit());
    for (final outfit in const [
      RobotOutfit(hat: RobotHat.wizard),
      RobotOutfit(hat: RobotHat.topHat),
      RobotOutfit(hat: RobotHat.turban, head: RobotHead.visor),
      RobotOutfit(hat: RobotHat.wizard, head: RobotHead.visor),
    ]) {
      final other = await body(outfit);
      expect(other.bottom, fez.bottom, reason: '$outfit: its feet where they were');
      expect(other.top, greaterThan(4), reason: '$outfit: its hat inside the stage');
    }
    // Before, a wizard's hat made the whole robot smaller, and its feet narrower.
    final wizard = await _painted(_robot(const RobotOutfit(hat: RobotHat.wizard)), _stage);
    expect(wizard.width, closeTo(fez.width, 2));
  });

  test('the head is the same size whatever hat it wears', () async {
    final fez = await _painted(RobotHeadPainter(face: RobotFace.calm), const Size.square(120));
    final wizard = await _painted(
      RobotHeadPainter(face: RobotFace.calm, outfit: const RobotOutfit(hat: RobotHat.wizard)),
      const Size.square(120),
    );
    expect(wizard.bottom, fez.bottom);
    expect(wizard.left, closeTo(fez.left, 1));
  });
}

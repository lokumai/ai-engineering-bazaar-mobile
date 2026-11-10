import 'package:alchemist/alchemist.dart';
import 'package:ai_engineering_bazaar/shared/design_system/bazaar_theme.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/bazaar_card.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/completion_dial.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/lattice_band.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_hue.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/level_key.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/section_rule.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segment_meter.dart';
import 'package:ai_engineering_bazaar/shared/design_system/widgets/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  Widget sized(Widget child) => SizedBox(width: 320, child: child);

  GoldenTestGroup grid() => GoldenTestGroup(
    columns: 2,
    children: [
      GoldenTestScenario(name: 'lattice band', child: sized(const LatticeBand())),
      GoldenTestScenario(
        name: 'section rule',
        child: sized(const SectionRule(title: 'Levels')),
      ),
      GoldenTestScenario(
        name: 'level hues and dials',
        child: Builder(
          builder: (context) => Row(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var position = 0; position < 5; position++)
                Column(
                  spacing: 4,
                  children: [
                    LevelKey(color: levelHue(context, position)),
                    CompletionDial(
                      done: position,
                      total: 4,
                      color: levelHue(context, position),
                      center: '$position/4',
                      semanticLabel: '',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      GoldenTestScenario(
        name: 'segment meter',
        child: sized(
          const SegmentMeter(
            done: 3,
            total: 8,
            color: Color(0xff2f8c86),
            current: 3,
            currentColor: Color(0xff282864),
            semanticLabel: '',
          ),
        ),
      ),
      for (final shape in BazaarCardShape.values)
        GoldenTestScenario(
          name: 'card ${shape.name}',
          child: sized(
            BazaarCard(
              shape: shape,
              accent: shape == BazaarCardShape.plain ? const Color(0xff2f8c86) : null,
              child: const Text('Alpha'),
            ),
          ),
        ),
      GoldenTestScenario(
        name: 'segmented control',
        // A fixed size answers the golden table's intrinsic measure, which a LayoutBuilder cannot.
        child: SizedBox(
          width: 320,
          height: 56,
          child: BazaarSegmentedControl<int>(
            semanticLabel: '',
            selected: 0,
            onSelected: (_) {},
            segments: const [
              BazaarSegment(value: 0, label: 'For Engineers'),
              BazaarSegment(value: 1, label: 'For Everyone'),
            ],
          ),
        ),
      ),
    ],
  );

  goldenTest('Design pieces, light', fileName: 'design_pieces_light', builder: grid);

  goldenTest(
    'Design pieces, dark',
    fileName: 'design_pieces_dark',
    builder: () => Theme(
      data: bazaarTheme(brightness: Brightness.dark, platform: TargetPlatform.android),
      child: grid(),
    ),
  );
}

import 'package:ai_engineering_bazaar/shared/haptics/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Recorded implements IHaptics {
  final played = <HapticKind>[];

  @override
  Future<void> play(HapticKind kind) async => played.add(kind);
}

void main() {
  late List<Object?> vibrations;

  setUp(() {
    vibrations = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') vibrations.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  });

  test("Flutter's own feedback plays each kind as UIKit's tap of its weight (plan 18.12)", () async {
    for (final kind in HapticKind.values) {
      await const FlutterHaptics().play(kind);
    }
    expect(vibrations, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  testWidgets('a widget plays the haptics the app provides, or Flutter\'s own where none is', (tester) async {
    final provided = _Recorded();
    late BuildContext withPort;
    late BuildContext without;
    await tester.pumpWidget(
      Column(
        children: [
          RepositoryProvider<IHaptics>.value(
            value: provided,
            child: Builder(
              builder: (context) {
                withPort = context;
                return const SizedBox();
              },
            ),
          ),
          Builder(
            builder: (context) {
              without = context;
              return const SizedBox();
            },
          ),
        ],
      ),
    );
    withPort.haptic(HapticKind.medium);
    without.haptic(HapticKind.selection);
    await tester.pump();
    expect(provided.played, [HapticKind.medium]);
    expect(vibrations, ['HapticFeedbackType.selectionClick']);
  });
}

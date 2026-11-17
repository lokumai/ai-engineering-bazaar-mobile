import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_cubit.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at the design\'s own, then reads what was kept', () async {
    final store = MemoryReadingStyleStore(const ReadingStyle(size: ReadingSize.large));
    final cubit = ReadingStyleCubit(store: store);
    addTearDown(cubit.close);
    expect(cubit.state, ReadingStyle.standard);

    await cubit.load();

    expect(cubit.state, const ReadingStyle(size: ReadingSize.large));
  });

  test('a size and a spacing chosen are current and kept; reset goes back to the default', () async {
    final store = MemoryReadingStyleStore();
    final cubit = ReadingStyleCubit(store: store);
    addTearDown(cubit.close);

    await cubit.chooseSize(ReadingSize.largest);
    await cubit.chooseSpacing(ReadingSpacing.tight);
    const chosen = ReadingStyle(size: ReadingSize.largest, spacing: ReadingSpacing.tight);
    expect(cubit.state, chosen);
    expect(await store.chosen(), chosen);

    await cubit.reset();
    expect(cubit.state, ReadingStyle.standard);
    expect(await store.chosen(), ReadingStyle.standard);
  });

  test('the default is the design: the phone\'s text size and the body\'s own line height', () {
    expect(ReadingSize.standard.factor, 1);
    expect(ReadingSpacing.comfortable.lineHeight, 1.68);
  });
}

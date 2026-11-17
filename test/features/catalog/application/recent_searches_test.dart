@Tags(['unit'])
library;

import 'package:ai_engineering_bazaar/features/catalog/application/recent_searches.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecentSearchesCubit cubit([MemoryRecentSearchStore? store]) {
    final cubit = RecentSearchesCubit(store: store);
    addTearDown(cubit.close);
    return cubit;
  }

  test('the latest first, trimmed, one of each whatever its case, five at the most', () async {
    final store = MemoryRecentSearchStore();
    final recent = cubit(store);
    for (final query in ['rag', ' tokens ', 'agents', 'memory', 'tools', 'evals', 'RAG']) {
      await recent.add(query);
    }
    expect(recent.state, ['RAG', 'evals', 'tools', 'memory', 'agents']);
    expect(await store.read(), recent.state, reason: 'kept');
    await recent.add('   ');
    expect(recent.state.first, 'RAG', reason: 'no empty search');
  });

  test('one is removed, then all are cleared', () async {
    final recent = cubit(MemoryRecentSearchStore(['a', 'b', 'c']));
    await recent.load();
    await recent.remove('b');
    expect(recent.state, ['a', 'c']);
    await recent.clear();
    expect(recent.state, isEmpty);
  });

  test('the file\'s shape, and anything else reads as none', () {
    expect(decodeRecentSearches(encodeRecentSearches(['x', 'y'])), ['x', 'y']);
    expect(decodeRecentSearches('not json'), isEmpty);
    expect(decodeRecentSearches('{"schema":2,"searches":["x"]}'), isEmpty);
    expect(decodeRecentSearches('{"schema":1,"searches":["x", 3, " "]}'), ['x']);
  });
}

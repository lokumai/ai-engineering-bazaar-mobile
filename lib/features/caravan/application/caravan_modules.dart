import 'package:ai_engineering_bazaar/features/caravan/domain/caravan_trend.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/bundle_index.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:equatable/equatable.dart';

/// A module of the course on a trend's subject, as its card links it.
final class CaravanModule extends Equatable {
  const CaravanModule({required this.key, required this.title});

  /// The module's key, `<level>/<module>`.
  final String key;

  /// Its title in the reader's language.
  final String title;

  @override
  List<Object?> get props => [key, title];
}

/// The modules [trend] names that the course has written in [track], in the order the trend names them, each once,
/// titled in [language].
///
/// A trend names a module by its name alone, the last segment of its key, as the web's `curriculum.yaml` does; a name
/// the bundle does not carry, or a module not written in [track], is left out, as the web drops a module that no longer
/// resolves rather than show a dead link.
List<CaravanModule> courseModules(CaravanTrend trend, BundleIndex index, Track track, String language) {
  final found = <CaravanModule>[];
  for (final name in trend.modules) {
    for (final module in index.modules) {
      if (module.key.split('/').last != name) continue;
      final entry = module.tracks[track];
      if (entry == null || !entry.drawn) continue;
      if (found.any((other) => other.key == module.key)) continue;
      found.add(CaravanModule(key: module.key, title: entry.titleIn(language)));
    }
  }
  return found;
}

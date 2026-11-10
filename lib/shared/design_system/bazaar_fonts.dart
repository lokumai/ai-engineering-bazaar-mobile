import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The family every diagram label names (`font-family="Vazirmatn"`), bundled from `assets/fonts/` so the labels are
/// set in the face the web measured them with (spec 1.4 decision 8).
const String diagramFontFamily = 'Vazirmatn';

/// The sans family for [platform] (spec 1.4 decision 5): Avenir Next on iOS; null on Android and elsewhere, which
/// leaves the platform default face.
String? sansFamily(TargetPlatform platform) => platform == TargetPlatform.iOS ? 'Avenir Next' : null;

/// The mono family for [platform]: Menlo on iOS, `monospace` elsewhere. A recorded deviation from the web's
/// `ui-monospace` (`bazaar.css:164`), which no Flutter platform resolves.
String monoFamily(TargetPlatform platform) => platform == TargetPlatform.iOS ? 'Menlo' : 'monospace';

/// Adds the SIL Open Font License of each bundled face to the [LicenseRegistry], so the licences page lists them:
/// Vazirmatn (spec 1.4 decisions 5 and 8) and Fraunces, the face of the story's headings (plan 3.5). The app calls it
/// once at start-up; this is the only registration.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [diagramFontFamily], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const ['Fraunces'], await rootBundle.loadString('assets/fonts/OFL-Fraunces.txt'));
  });
}

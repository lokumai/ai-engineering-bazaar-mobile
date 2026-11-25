import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Material's own words in English as `en-GB` writes them, as the app's copy and dates do (`shortDate`): the licences
/// page is titled Licences, as the Settings row that opens it (walk-through 2026-11-24). Turkish and Persian are left
/// to [GlobalMaterialLocalizations.delegate], which comes after this one.
class BritishMaterialLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const BritishMaterialLocalizations();

  static const delegate = BritishMaterialLocalizations();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en', 'GB'));

  @override
  bool shouldReload(BritishMaterialLocalizations old) => false;
}

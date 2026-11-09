// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Could not open {url}`
  String error_link_open_failed(String url) {
    return Intl.message('Could not open $url', name: 'error_link_open_failed', desc: '', args: [url]);
  }

  /// `No such module`
  String get not_found_title {
    return Intl.message('No such module', name: 'not_found_title', desc: '', args: []);
  }

  /// `This address is not a module in the curriculum. The catalog lists every one that is.`
  String get not_found_message {
    return Intl.message(
      'This address is not a module in the curriculum. The catalog lists every one that is.',
      name: 'not_found_message',
      desc: '',
      args: [],
    );
  }

  /// `AI Engineering Bazaar`
  String get app_title {
    return Intl.message('AI Engineering Bazaar', name: 'app_title', desc: '', args: []);
  }

  /// `Catalog`
  String get nav_catalog {
    return Intl.message('Catalog', name: 'nav_catalog', desc: '', args: []);
  }

  /// `Progress`
  String get nav_progress {
    return Intl.message('Progress', name: 'nav_progress', desc: '', args: []);
  }

  /// `Settings`
  String get nav_settings {
    return Intl.message('Settings', name: 'nav_settings', desc: '', args: []);
  }

  /// `Track`
  String get track_switch_label {
    return Intl.message('Track', name: 'track_switch_label', desc: '', args: []);
  }

  /// `Open on the web`
  String get open_on_the_web {
    return Intl.message('Open on the web', name: 'open_on_the_web', desc: '', args: []);
  }

  /// `The course cannot be opened`
  String get content_broken_title {
    return Intl.message('The course cannot be opened', name: 'content_broken_title', desc: '', args: []);
  }

  /// `The course content in this app could not be read. Reinstalling the app restores it.`
  String get content_broken_message {
    return Intl.message(
      'The course content in this app could not be read. Reinstalling the app restores it.',
      name: 'content_broken_message',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message('Loading', name: 'loading', desc: '', args: []);
  }

  /// `Catalog`
  String get catalog_title {
    return Intl.message('Catalog', name: 'catalog_title', desc: '', args: []);
  }

  /// `Level:`
  String get catalog_level_label {
    return Intl.message('Level:', name: 'catalog_level_label', desc: '', args: []);
  }

  /// `Status:`
  String get catalog_status_label {
    return Intl.message('Status:', name: 'catalog_status_label', desc: '', args: []);
  }

  /// `All`
  String get catalog_filter_all {
    return Intl.message('All', name: 'catalog_filter_all', desc: '', args: []);
  }

  /// `Ready`
  String get catalog_filter_ready {
    return Intl.message('Ready', name: 'catalog_filter_ready', desc: '', args: []);
  }

  /// `Planned`
  String get catalog_filter_planned {
    return Intl.message('Planned', name: 'catalog_filter_planned', desc: '', args: []);
  }

  /// `Completed`
  String get catalog_filter_completed {
    return Intl.message('Completed', name: 'catalog_filter_completed', desc: '', args: []);
  }

  /// `Not completed`
  String get catalog_filter_not_completed {
    return Intl.message('Not completed', name: 'catalog_filter_not_completed', desc: '', args: []);
  }

  /// `Showing {visible} of {total}`
  String catalog_showing(int visible, int total) {
    return Intl.message('Showing $visible of $total', name: 'catalog_showing', desc: '', args: [visible, total]);
  }

  /// `No module matches both filters · 0 of {total}`
  String catalog_no_match(int total) {
    return Intl.message(
      'No module matches both filters · 0 of $total',
      name: 'catalog_no_match',
      desc: '',
      args: [total],
    );
  }

  /// `The two filters select different modules. Widen either one, or clear both to see the whole catalog again.`
  String get catalog_no_match_cue {
    return Intl.message(
      'The two filters select different modules. Widen either one, or clear both to see the whole catalog again.',
      name: 'catalog_no_match_cue',
      desc: '',
      args: [],
    );
  }

  /// `Show the whole catalog`
  String get catalog_show_all {
    return Intl.message('Show the whole catalog', name: 'catalog_show_all', desc: '', args: []);
  }

  /// `{ready} of {total} written`
  String catalog_written(int ready, int total) {
    return Intl.message('$ready of $total written', name: 'catalog_written', desc: '', args: [ready, total]);
  }

  /// `Planned`
  String get module_planned {
    return Intl.message('Planned', name: 'module_planned', desc: '', args: []);
  }

  /// `{count, plural, =1{1 module} other{{count} modules}}`
  String level_module_count(int count) {
    return Intl.plural(
      count,
      one: '1 module',
      other: '$count modules',
      name: 'level_module_count',
      desc: '',
      args: [count],
    );
  }

  /// `~{minutes} min`
  String duration_minutes(int minutes) {
    return Intl.message('~$minutes min', name: 'duration_minutes', desc: '', args: [minutes]);
  }

  /// `~{hours} h`
  String duration_hours(int hours) {
    return Intl.message('~$hours h', name: 'duration_hours', desc: '', args: [hours]);
  }

  /// `~{hours} h {minutes} min`
  String duration_hours_minutes(int hours, int minutes) {
    return Intl.message('~$hours h $minutes min', name: 'duration_hours_minutes', desc: '', args: [hours, minutes]);
  }

  /// `{approved}/{total} completed`
  String level_completed(int approved, int total) {
    return Intl.message('$approved/$total completed', name: 'level_completed', desc: '', args: [approved, total]);
  }

  /// `--/{total} completed`
  String level_completed_pending(int total) {
    return Intl.message('--/$total completed', name: 'level_completed_pending', desc: '', args: [total]);
  }

  /// `Description`
  String get card_description {
    return Intl.message('Description', name: 'card_description', desc: '', args: []);
  }

  /// `Length`
  String get card_length {
    return Intl.message('Length', name: 'card_length', desc: '', args: []);
  }

  /// `{minutes} min`
  String card_length_minutes(int minutes) {
    return Intl.message('$minutes min', name: 'card_length_minutes', desc: '', args: [minutes]);
  }

  /// `Requires`
  String get card_requires {
    return Intl.message('Requires', name: 'card_requires', desc: '', args: []);
  }

  /// `Nothing`
  String get card_requires_nothing {
    return Intl.message('Nothing', name: 'card_requires_nothing', desc: '', args: []);
  }

  /// `This part of the course could not be read on this device. Restart the app to reload it.`
  String get content_unreadable {
    return Intl.message(
      'This part of the course could not be read on this device. Restart the app to reload it.',
      name: 'content_unreadable',
      desc: '',
      args: [],
    );
  }

  /// `FIG. {number}`
  String block_figure_caption(String number) {
    return Intl.message('FIG. $number', name: 'block_figure_caption', desc: '', args: [number]);
  }

  /// `TBL. {number}`
  String block_table_caption(String number) {
    return Intl.message('TBL. $number', name: 'block_table_caption', desc: '', args: [number]);
  }

  /// `This part needs a newer version of the app.`
  String get block_unknown {
    return Intl.message('This part needs a newer version of the app.', name: 'block_unknown', desc: '', args: []);
  }

  /// `{language} code`
  String block_code_label(String language) {
    return Intl.message('$language code', name: 'block_code_label', desc: '', args: [language]);
  }

  /// `Program output`
  String get block_program_output {
    return Intl.message('Program output', name: 'block_program_output', desc: '', args: []);
  }

  /// `Table {number}`
  String block_table_region(String number) {
    return Intl.message('Table $number', name: 'block_table_region', desc: '', args: [number]);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}

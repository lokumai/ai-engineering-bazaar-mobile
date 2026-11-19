import 'package:ai_engineering_bazaar/shared/language/language_cubit.dart';
import 'package:ai_engineering_bazaar/shared/language/language_store.dart';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:ai_engineering_bazaar/core/analytics/analytics_service.dart';
import 'package:ai_engineering_bazaar/core/analytics/log_analytics_service.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/pocket_model_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/application/robot_outfit_store.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/robot_outfit.dart';
import 'package:ai_engineering_bazaar/features/pocket_model/domain/pocket_model.dart';
import 'package:ai_engineering_bazaar/features/settings/application/feedback_sender.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_page.dart';
import 'package:ai_engineering_bazaar/features/tour/domain/tour_record.dart';
import 'package:ai_engineering_bazaar/features/welcome/application/welcome_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/analytics/sentry_feedback.dart';
import 'package:ai_engineering_bazaar/infrastructure/app_icon/app_icon_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/theme/launch_ground_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/backup/platform_backup_gateway.dart';
import 'package:ai_engineering_bazaar/infrastructure/config/environment.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/bundled_content.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/content_http.dart';
import 'package:ai_engineering_bazaar/infrastructure/content/file_content_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/flags/file_flag_store.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/record/file_record_repository.dart';
import 'package:ai_engineering_bazaar/infrastructure/storage/text/file_text_store.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score.dart';
import 'package:ai_engineering_bazaar/shared/quiz_scores/domain/quiz_score_store.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_history.dart';
import 'package:ai_engineering_bazaar/shared/review/domain/review_store.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place.dart';
import 'package:ai_engineering_bazaar/shared/reading/domain/reading_place_store.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/content_repository.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/backup_gateway.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/record_repository.dart';
import 'package:ai_engineering_bazaar/shared/content/domain/track.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:ai_engineering_bazaar/shared/pocket_button/pocket_button_store.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style.dart';
import 'package:ai_engineering_bazaar/shared/reading_style/reading_style_store.dart';
import 'package:ai_engineering_bazaar/shared/theme/theme_store.dart';
import 'package:ai_engineering_bazaar/shared/track/track_store.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/listen_place.dart';
import 'package:ai_engineering_bazaar/shared/listen/domain/speech.dart';
import 'package:ai_engineering_bazaar/infrastructure/speech/phone_speech.dart';
import 'package:ai_engineering_bazaar/infrastructure/haptics/haptics_channel.dart';
import 'package:ai_engineering_bazaar/shared/haptics/haptics.dart';
import 'package:ai_engineering_bazaar/infrastructure/links/link_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/share/share_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/scanner/code_scanner_channel.dart';
import 'package:ai_engineering_bazaar/infrastructure/transfer/deflate_transfer_packer.dart';
import 'package:ai_engineering_bazaar/shared/record/domain/transfer.dart';
import 'package:ai_engineering_bazaar/shared/site_links/domain/site_link_ports.dart';

/// Builds the infrastructure the app runs on; a test subclass overrides the factories with doubles.
class AppDependencies {
  const AppDependencies({
    this.appConfig = const AppConfig.dev(),
    @visibleForTesting this.cacheDirectory = getApplicationCacheDirectory,
    @visibleForTesting this.supportDirectory = getApplicationSupportDirectory,
  });

  final AppConfig appConfig;

  /// Where the downloaded content is stored; resolved by the repository's `open()`, not here.
  final Future<Directory> Function() cacheDirectory;

  /// Where the record is stored (spec 3.3.9); resolved by the record repository on first use, not here.
  final Future<Directory> Function() supportDirectory;

  /// Crash reporting logs through this on the device; Sentry's own hooks report crashes when a DSN is set.
  IAnalyticsService createAnalyticsService() => LogAnalyticsService();

  /// The content repository over the bundled snapshot, the cache directory and the site at
  /// [AppConfig.contentBaseUrl]; built synchronously, it touches no file until `open()`.
  IContentRepository createContentRepository() => FileContentRepository(
    bundled: BundledContent(bundle: rootBundle),
    cacheDirectory: cacheDirectory,
    http: ContentHttp(client: http.Client(), contentBaseUrl: appConfig.contentBaseUrl),
  );

  /// The record repository over files under [supportDirectory]`/record/`; it touches no file until first use.
  IRecordRepository createRecordRepository() => FileRecordRepository(baseDirectory: supportDirectory);

  /// The backup gateway over the platform's save dialog and file picker; it opens nothing until called.
  IBackupGateway createBackupGateway() => PlatformBackupGateway();

  /// Whether Welcome was seen, as a file flag under [supportDirectory]`/flags/`, apart from the record.
  IWelcomeStore createWelcomeStore() => FlagWelcomeStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen track, as file flags under [supportDirectory]`/flags/`, apart from the record (plan 1L).
  ITrackStore createTrackStore() => FlagTrackStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen language, as file flags under [supportDirectory]`/flags/`, apart from the record (plan 1Q).
  ILanguageStore createLanguageStore() => FlagLanguageStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The chosen look (light or dark), as file flags under [supportDirectory]`/flags/`, apart from the record.
  IThemeStore createThemeStore() => FlagThemeStore(FileFlagStore(baseDirectory: supportDirectory));

  /// Names the chosen look to the phone, so the next launch opens on its page colour, over the native channel.
  ILaunchGround createLaunchGround() => const ChannelLaunchGround(LaunchGroundChannel());

  /// The chosen app icon, as file flags under [supportDirectory]`/flags/`, apart from the record.
  IAppIconStore createAppIconStore() => FlagAppIconStore(FileFlagStore(baseDirectory: supportDirectory));

  /// Whether the pocket model's round button is hidden, as a file flag under [supportDirectory]`/flags/` (plan 9.9).
  IPocketButtonStore createPocketButtonStore() => FlagPocketButtonStore(FileFlagStore(baseDirectory: supportDirectory));

  /// The reading settings, as file flags under [supportDirectory]`/flags/`, apart from the record (plan 12.5).
  IReadingStyleStore createReadingStyleStore() => FlagReadingStyleStore(FileFlagStore(baseDirectory: supportDirectory));

  ITourStore createTourStore() => FlagTourStore(FileFlagStore(baseDirectory: supportDirectory));

  /// Puts the chosen app icon on the home screen, over the native channel.
  IAppIconSwitch createAppIconSwitch() => const ChannelAppIconSwitch(AppIconChannel());

  /// The phone's own voice, which reads a module aloud (plan 15.1).
  ISpeech createSpeech() => PhoneSpeechPort(PhoneSpeech());

  /// The touch feedback (plan 18.12): Flutter's own on iOS, the app's channel on Android.
  IHaptics createHaptics() =>
      defaultTargetPlatform == TargetPlatform.android ? const ChannelHaptics(HapticsChannel()) : const FlutterHaptics();

  /// The site's links the phone hands the app (plan 17.2), over the native channel.
  ILinkSource createLinkSource() => ChannelLinkSource(LinkChannel());

  /// The phone's share sheet (plan 17.3), over the native channel.
  IShareSheet createShareSheet() => const ChannelShareSheet(ShareChannel());

  /// The phone's QR code scanner (plan 17.5), over the native channel.
  ICodeScanner createCodeScanner() => const ChannelCodeScanner(CodeScannerChannel());

  /// Packs and unpacks a progress transfer's payload (plan 17.1).
  ITransferPacker createTransferPacker() => const DeflateTransferPacker();

  /// Where each module read aloud was left and which parts were heard, as one file under
  /// [supportDirectory]`/listen/places.json`, apart from the record (the owner, 2026-11-18).
  IListenPlaceStore createListenPlaceStore() =>
      FileListenPlaceStore(FileTextStore(baseDirectory: supportDirectory, path: 'listen/places.json'));

  /// The quiz scores, as one file under [supportDirectory]`/quiz/scores.json`, apart from the record (plan 1W).
  IQuizScoreStore createQuizScoreStore() =>
      FileQuizScoreStore(FileTextStore(baseDirectory: supportDirectory, path: 'quiz/scores.json'));

  /// Practice's history, as one file under [supportDirectory]`/quiz/review.json`, beside the scores and apart from the
  /// record (plan 13.1).
  IReviewStore createReviewStore() =>
      FileReviewStore(FileTextStore(baseDirectory: supportDirectory, path: 'quiz/review.json'));

  /// Where each module was left, as one file under [supportDirectory]`/reading/places.json`, apart from the record
  /// (plan 1BA).
  IReadingPlaceStore createReadingPlaceStore() =>
      FileReadingPlaceStore(FileTextStore(baseDirectory: supportDirectory, path: 'reading/places.json'));

  /// Home's pocket model, as one file under [supportDirectory]`/toy/pocket_model.json`, apart from the record
  /// (plan 9.2), and the temperature the reader set beside it in `/toy/temperature.txt`.
  IPocketModelStore createPocketModelStore() => FilePocketModelStore(
    FileTextStore(baseDirectory: supportDirectory, path: 'toy/pocket_model.json'),
    temperature: FileTextStore(baseDirectory: supportDirectory, path: 'toy/temperature.txt'),
  );

  /// The robot's outfit, as one file under [supportDirectory]`/toy/outfit.json`, apart from the record (plan 9.9).
  IRobotOutfitStore createRobotOutfitStore() =>
      FileRobotOutfitStore(FileTextStore(baseDirectory: supportDirectory, path: 'toy/outfit.json'));

  /// Report a problem's sender, over Sentry's user feedback; Settings shows the page only when Sentry is on.
  IFeedbackSender createFeedbackSender() => const SentryFeedbackSender();
}

/// Report a problem's port over Sentry's user feedback ([sendSentryFeedback]).
final class SentryFeedbackSender implements IFeedbackSender {
  const SentryFeedbackSender();

  @override
  Future<void> send(String message) => sendSentryFeedback(message);
}

/// The reading places' port over one text file of the app's own.
final class FileReadingPlaceStore implements IReadingPlaceStore {
  const FileReadingPlaceStore(this._file);

  final FileTextStore _file;

  @override
  Future<Map<String, ReadingPlace>> load() async {
    final text = await _file.read();
    return text == null ? const {} : decodeReadingPlaces(text);
  }

  @override
  Future<void> save(Map<String, ReadingPlace> places) =>
      places.isEmpty ? _file.delete() : _file.write(encodeReadingPlaces(places));
}

/// The listening places' port over one text file of the app's own.
final class FileListenPlaceStore implements IListenPlaceStore {
  const FileListenPlaceStore(this._file);

  final FileTextStore _file;

  @override
  Future<Map<String, ListenPlace>> load() async {
    final text = await _file.read();
    return text == null ? const {} : decodeListenPlaces(text);
  }

  @override
  Future<void> save(Map<String, ListenPlace> places) =>
      places.isEmpty ? _file.delete() : _file.write(encodeListenPlaces(places));
}

/// The pocket model's port over one text file of the app's own.
final class FilePocketModelStore implements IPocketModelStore {
  const FilePocketModelStore(this._file, {required this._temperature});

  final FileTextStore _file;
  final FileTextStore _temperature;

  @override
  Future<PocketModel?> load() async {
    final text = await _file.read();
    return text == null ? null : decodePocketModel(text);
  }

  @override
  Future<void> save(PocketModel model) => _file.write(encodePocketModel(model));

  @override
  Future<double?> loadTemperature() async {
    final text = await _temperature.read();
    return text == null ? null : decodePocketTemperature(text);
  }

  @override
  Future<void> saveTemperature(double temperature) => _temperature.write('$temperature');
}

/// The quiz scores' port over one text file of the app's own.
final class FileQuizScoreStore implements IQuizScoreStore {
  const FileQuizScoreStore(this._file);

  final FileTextStore _file;

  @override
  Future<Map<String, QuizScore>> load() async {
    final text = await _file.read();
    return text == null ? const {} : decodeQuizScores(text);
  }

  @override
  Future<void> save(Map<String, QuizScore> scores) =>
      scores.isEmpty ? _file.delete() : _file.write(encodeQuizScores(scores));
}

/// Practice's history's port over one text file of the app's own.
final class FileReviewStore implements IReviewStore {
  const FileReviewStore(this._file);

  final FileTextStore _file;

  @override
  Future<ReviewHistory> load() async {
    final text = await _file.read();
    return text == null ? ReviewHistory.empty : decodeReviewHistory(text);
  }

  @override
  Future<void> save(ReviewHistory history) =>
      history.isEmpty ? _file.delete() : _file.write(encodeReviewHistory(history));
}

/// The welcome feature's port over the app's file flags: the flag `welcome-2-seen`. Welcome 2 asks for the track
/// (plan 1L), so a reader who saw the first Welcome (`welcome-seen`) sees it once more.
final class FlagWelcomeStore implements IWelcomeStore {
  const FlagWelcomeStore(this._flags);

  final FileFlagStore _flags;

  static const _flag = 'welcome-2-seen';

  @override
  Future<bool> seen() => _flags.isSet(_flag);

  @override
  Future<void> markSeen() => _flags.set(_flag);
}

/// The track cubit's port over the app's file flags: `track-chosen` once a track was chosen, and `track-everyone` while
/// that choice is For Everyone.
final class FlagTrackStore implements ITrackStore {
  const FlagTrackStore(this._flags);

  final FileFlagStore _flags;

  static const _chosen = 'track-chosen';
  static const _everyone = 'track-everyone';

  @override
  Future<Track?> chosen() async {
    if (!await _flags.isSet(_chosen)) return null;
    return await _flags.isSet(_everyone) ? Track.everyone : Track.engineers;
  }

  @override
  Future<void> choose(Track track) async {
    if (track == Track.everyone) {
      await _flags.set(_everyone);
    } else {
      await _flags.clear(_everyone);
    }
    await _flags.set(_chosen);
  }
}

/// The language cubit's port over the app's file flags: `language-<code>` for the chosen language, at most one set.
/// No flag set means no language was chosen yet.
final class FlagLanguageStore implements ILanguageStore {
  const FlagLanguageStore(this._flags);

  final FileFlagStore _flags;

  static String _flag(String language) => 'language-$language';

  @override
  Future<String?> chosen() async {
    for (final language in LanguageCubit.supported) {
      if (await _flags.isSet(_flag(language))) return language;
    }
    return null;
  }

  @override
  Future<void> choose(String language) async {
    for (final other in LanguageCubit.supported) {
      if (other != language) await _flags.clear(_flag(other));
    }
    await _flags.set(_flag(language));
  }
}

/// The pocket button's port over the app's file flags: `pocket-button-hidden` set when the reader hid it.
final class FlagPocketButtonStore implements IPocketButtonStore {
  const FlagPocketButtonStore(this._flags);

  final FileFlagStore _flags;

  static const _flag = 'pocket-button-hidden';

  @override
  Future<bool> hidden() => _flags.isSet(_flag);

  @override
  Future<void> hide({required bool hidden}) => hidden ? _flags.set(_flag) : _flags.clear(_flag);
}

/// The tour's port over the app's file flags (plan 11.3): `tour-asking` while the Apprentice is to ask, `tour-guiding`
/// once the reader said yes, and `tour-seen-<page>` for each page shown.
final class FlagTourStore implements ITourStore {
  const FlagTourStore(this._flags);

  final FileFlagStore _flags;

  static const _asking = 'tour-asking';
  static const _guiding = 'tour-guiding';
  static String _seen(TourPage page) => 'tour-seen-${page.name}';

  @override
  Future<TourRecord> load() async => TourRecord(
    asking: await _flags.isSet(_asking),
    guiding: await _flags.isSet(_guiding),
    seen: {
      for (final page in TourPage.values)
        if (await _flags.isSet(_seen(page))) page.name,
    },
  );

  @override
  Future<void> save(TourRecord record) async {
    Future<void> flag(String name, {required bool on}) => on ? _flags.set(name) : _flags.clear(name);
    await flag(_asking, on: record.asking);
    await flag(_guiding, on: record.guiding);
    for (final page in TourPage.values) {
      await flag(_seen(page), on: record.seen.contains(page.name));
    }
  }
}

/// The robot's outfit in one text file.
final class FileRobotOutfitStore implements IRobotOutfitStore {
  const FileRobotOutfitStore(this._file);

  final FileTextStore _file;

  @override
  Future<RobotOutfit?> load() async {
    final text = await _file.read();
    return text == null ? null : decodeRobotOutfit(text);
  }

  @override
  Future<void> save(RobotOutfit outfit) => _file.write(encodeRobotOutfit(outfit));
}

/// The reading style cubit's port over the app's file flags (plan 12.5): `reading-size-<name>` and
/// `reading-spacing-<name>`, at most one of each set. No flag set means the design's own.
final class FlagReadingStyleStore implements IReadingStyleStore {
  const FlagReadingStyleStore(this._flags);

  final FileFlagStore _flags;

  static String _size(ReadingSize size) => 'reading-size-${size.name}';
  static String _spacing(ReadingSpacing spacing) => 'reading-spacing-${spacing.name}';

  @override
  Future<ReadingStyle> chosen() async {
    var style = ReadingStyle.standard;
    for (final size in ReadingSize.values) {
      if (await _flags.isSet(_size(size))) style = style.copyWith(size: size);
    }
    for (final spacing in ReadingSpacing.values) {
      if (await _flags.isSet(_spacing(spacing))) style = style.copyWith(spacing: spacing);
    }
    return style;
  }

  @override
  Future<void> keep(ReadingStyle style) async {
    for (final size in ReadingSize.values) {
      if (size != style.size) await _flags.clear(_size(size));
    }
    for (final spacing in ReadingSpacing.values) {
      if (spacing != style.spacing) await _flags.clear(_spacing(spacing));
    }
    // The design's own is no flag at all.
    if (style.size != ReadingSize.standard) await _flags.set(_size(style.size));
    if (style.spacing != ReadingSpacing.comfortable) await _flags.set(_spacing(style.spacing));
  }
}

/// The theme cubit's port over the app's file flags: `theme-light` or `theme-dark`, at most one set. No flag set means
/// no choice was made, or the phone was chosen.
final class FlagThemeStore implements IThemeStore {
  const FlagThemeStore(this._flags);

  final FileFlagStore _flags;

  static const _explicit = {ThemeMode.light: 'theme-light', ThemeMode.dark: 'theme-dark'};

  @override
  Future<ThemeMode?> chosen() async {
    for (final entry in _explicit.entries) {
      if (await _flags.isSet(entry.value)) return entry.key;
    }
    return null;
  }

  @override
  Future<void> choose(ThemeMode mode) async {
    for (final entry in _explicit.entries) {
      if (entry.key != mode) await _flags.clear(entry.value);
    }
    final flag = _explicit[mode];
    if (flag != null) await _flags.set(flag);
  }
}

/// The app icon cubit's store over the app's file flags: `app-icon-<name>` for the chosen icon, at most one set. No
/// flag set means no icon was chosen yet.
final class FlagAppIconStore implements IAppIconStore {
  const FlagAppIconStore(this._flags);

  final FileFlagStore _flags;

  static String _flag(BazaarIcon icon) => 'app-icon-${icon.name}';

  @override
  Future<BazaarIcon?> chosen() async {
    for (final icon in BazaarIcon.values) {
      if (await _flags.isSet(_flag(icon))) return icon;
    }
    return null;
  }

  @override
  Future<void> choose(BazaarIcon icon) async {
    for (final other in BazaarIcon.values) {
      if (other != icon) await _flags.clear(_flag(other));
    }
    await _flags.set(_flag(icon));
  }
}

/// The app icon cubit's switch over the native channel, which names each icon by its [BazaarIcon.name].
final class ChannelAppIconSwitch implements IAppIconSwitch {
  const ChannelAppIconSwitch(this._channel);

  final AppIconChannel _channel;

  @override
  Future<void> choose(BazaarIcon icon) => _channel.choose(icon.name);
}

/// The reader's speech over the phone's own engine.
final class PhoneSpeechPort implements ISpeech {
  const PhoneSpeechPort(this._speech);

  final PhoneSpeech _speech;

  @override
  Future<bool> canSpeak(String language) => _speech.canSpeak(language);

  @override
  Future<void> speak(
    List<String> texts, {
    required String language,
    required double rate,
    required void Function(int index) onPart,
    String title = '',
  }) => _speech.speak(texts, language: language, rate: rate, onPart: onPart, title: title);

  @override
  Stream<void> get interruptions => _speech.interruptions;

  @override
  Stream<void> get resumes => _speech.resumes;

  @override
  Future<void> show(ShownReading? reading) => _speech.show(title: reading?.title, playing: reading?.playing ?? false);

  @override
  Future<void> stop() => _speech.stop();
}

/// Android's touch feedback over the native channel.
final class ChannelHaptics implements IHaptics {
  const ChannelHaptics(this._channel);

  final HapticsChannel _channel;

  @override
  Future<void> play(HapticKind kind) => _channel.play(kind.name);
}

/// The site's links over the native channel.
final class ChannelLinkSource implements ILinkSource {
  const ChannelLinkSource(this._channel);

  final LinkChannel _channel;

  @override
  Future<List<Uri>> takeWaiting() => _channel.takeWaiting();

  @override
  Stream<Uri> get links => _channel.links;
}

/// The phone's share sheet over the native channel.
final class ChannelShareSheet implements IShareSheet {
  const ChannelShareSheet(this._channel);

  final ShareChannel _channel;

  @override
  Future<bool> share(String text) => _channel.share(text);
}

/// The phone's QR code scanner over the native channel.
final class ChannelCodeScanner implements ICodeScanner {
  const ChannelCodeScanner(this._channel);

  final CodeScannerChannel _channel;

  @override
  Future<bool> available() => _channel.available();

  @override
  Future<ScanOutcome> scan(String title) async => switch (await _channel.scan(title)) {
    (text: final String text, error: _) => ScanRead(text),
    (text: null, error: null) => const ScanCancelled(),
    (text: null, error: 'denied') => const ScanDenied(),
    (text: null, error: _) => const ScanFailed(),
  };
}

/// The theme cubit's launch ground over the native channel: the light look, or the dark one for any other mode.
final class ChannelLaunchGround implements ILaunchGround {
  const ChannelLaunchGround(this._channel);

  final LaunchGroundChannel _channel;

  @override
  Future<void> keep(ThemeMode mode) => _channel.keep(dark: mode != ThemeMode.light);
}

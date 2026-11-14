import 'package:ai_engineering_bazaar/shared/app_icon/app_icon_ports.dart';
import 'package:ai_engineering_bazaar/shared/app_icon/bazaar_icon.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app icon: [AppIconUnread] until the choice kept on this device was read, then [AppIconKnown]. The opening
/// waits for it, so it plays in the chosen icon's colours from its first frame.
sealed class AppIconState extends Equatable {
  const AppIconState();

  /// The icon to show: the default until the choice was read.
  BazaarIcon get icon;
}

/// The choice is not read yet.
final class AppIconUnread extends AppIconState {
  const AppIconUnread();

  @override
  BazaarIcon get icon => BazaarIcon.defaultIcon;

  @override
  List<Object?> get props => const [];
}

/// The icon in use: the one chosen, or the default when none was.
final class AppIconKnown extends AppIconState {
  const AppIconKnown(this.icon);

  @override
  final BazaarIcon icon;

  @override
  List<Object?> get props => [icon];
}

/// The app's icon on the home screen, which the reader chooses in Settings (the owner, 2026-11-14);
/// [BazaarIcon.defaultIcon] until they do. The choice is kept by the [IAppIconStore], on this device and never in the
/// record, and put on the home screen by the [IAppIconSwitch], which each launch names it to again.
///
/// The boot reads the kept choice before the app's first frame and passes it as [initial], so the opening starts in
/// its colours; without it the cubit starts unread and [load] reads it.
final class AppIconCubit extends Cubit<AppIconState> {
  AppIconCubit({
    this._store = const MemoryAppIconStore(),
    this._iconSwitch = const NoAppIconSwitch(),
    BazaarIcon? initial,
  }) : super(initial == null ? const AppIconUnread() : AppIconKnown(initial));

  final IAppIconStore _store;
  final IAppIconSwitch _iconSwitch;

  /// Reads the chosen icon and makes it current, unless one was chosen meanwhile, and names it to the phone. With an
  /// [initial] icon there is nothing to read.
  Future<void> load() async {
    if (state case AppIconKnown(:final icon)) return _queue(() => _iconSwitch.choose(icon));
    final icon = await _store.chosen() ?? BazaarIcon.defaultIcon;
    if (isClosed || state is AppIconKnown) return;
    emit(AppIconKnown(icon));
    await _queue(() => _iconSwitch.choose(icon));
  }

  /// Makes [icon] current, keeps it as the reader's choice and puts it on the home screen.
  Future<void> choose(BazaarIcon icon) async {
    if (state != AppIconKnown(icon)) emit(AppIconKnown(icon));
    await _queue(() async {
      await _store.choose(icon);
      await _iconSwitch.choose(icon);
    });
  }

  /// Runs [work] after the work queued before it, so two quick choices are kept and switched in the order made.
  Future<void> _queue(Future<void> Function() work) async {
    final previous = _work;
    final running = _work = () async {
      // A failure was logged by the store or the switch; the next one still runs.
      await previous.catchError((Object _) {});
      await work();
    }();
    await running;
  }

  /// The last queued work, which the next one waits for.
  Future<void> _work = Future<void>.value();
}

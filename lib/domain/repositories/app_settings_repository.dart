import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/theme/app_theme_mode.dart';

/// Device-local app settings (shared-preferences backed). Presentation reads
/// these through use cases → this repository, never the datasource directly.
abstract class AppSettingsRepository {
  /// Whether the Nataraj first-run coach overlay ("Swipe to explore ideas")
  /// has been dismissed. Shown only once, ever.
  Future<Either<Failure, bool>> getNatarajCoachSeen();

  /// Persist that the Nataraj coach overlay has been seen/dismissed.
  Future<Either<Failure, Unit>> setNatarajCoachSeen(bool seen);

  /// Days after which short-lived public notes (Kind 1 / Kind 42) auto-evict;
  /// `null` = disabled. Read by CleanupManager at Gateway boot.
  Future<Either<Failure, int?>> getAutoDeleteOldNotesDays();

  /// Persist the auto-delete retention window (`null` = off).
  Future<Either<Failure, Unit>> setAutoDeleteOldNotesDays(int? days);

  /// Days of history the capped sync surfaces (feed / group / private-group
  /// messages) pull; defaults to 7. Read by the Gateway at boot.
  Future<Either<Failure, int>> getRecentSyncWindowDays();

  /// Persist the recent-sync window (days of history the capped surfaces pull).
  Future<Either<Failure, Unit>> setRecentSyncWindowDays(int days);

  /// Persist the user's chosen app language code (`'en'`, `'hi'`, …), or `null`
  /// to clear it and fall back to the system locale. The initial read is done
  /// synchronously at startup via the store; runtime changes flow through here.
  Future<Either<Failure, Unit>> setLocaleCode(String? code);

  /// Target language for note translation (BCP-47 primary subtag). `null`
  /// until the user has picked one.
  Future<Either<Failure, String?>> getTranslationLanguage();

  Future<Either<Failure, Unit>> setTranslationLanguage(String? code);

  /// Persist the user's chosen theme mode (system / light / dark). The
  /// initial value is read synchronously at startup via the store; runtime
  /// switches flow through here.
  Future<Either<Failure, Unit>> setThemeMode(AppThemeMode mode);
}

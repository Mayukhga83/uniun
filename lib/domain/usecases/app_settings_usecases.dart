import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/theme/app_theme_mode.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/repositories/app_settings_repository.dart';

/// Reads whether the Nataraj first-run coach overlay has been dismissed.
@lazySingleton
class GetNatarajCoachSeenUseCase
    extends NoParamsUseCase<Either<Failure, bool>> {
  final AppSettingsRepository _repository;
  const GetNatarajCoachSeenUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call() => _repository.getNatarajCoachSeen();
}

/// Persists that the Nataraj coach overlay has been seen/dismissed.
@lazySingleton
class SetNatarajCoachSeenUseCase extends UseCase<Either<Failure, Unit>, bool> {
  final AppSettingsRepository _repository;
  const SetNatarajCoachSeenUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(bool input, {bool cached = false}) =>
      _repository.setNatarajCoachSeen(input);
}

/// Reads the auto-delete retention window for short-lived public notes
/// (`null` = disabled).
@lazySingleton
class GetAutoDeleteOldNotesDaysUseCase
    extends NoParamsUseCase<Either<Failure, int?>> {
  final AppSettingsRepository _repository;
  const GetAutoDeleteOldNotesDaysUseCase(this._repository);

  @override
  Future<Either<Failure, int?>> call() =>
      _repository.getAutoDeleteOldNotesDays();
}

/// Persists the auto-delete retention window (`null` = off).
@lazySingleton
class SetAutoDeleteOldNotesDaysUseCase
    extends UseCase<Either<Failure, Unit>, int?> {
  final AppSettingsRepository _repository;
  const SetAutoDeleteOldNotesDaysUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(int? input, {bool cached = false}) =>
      _repository.setAutoDeleteOldNotesDays(input);
}

/// Reads the recent-sync window (days of history the capped surfaces pull;
/// defaults to 7).
@lazySingleton
class GetRecentSyncWindowDaysUseCase
    extends NoParamsUseCase<Either<Failure, int>> {
  final AppSettingsRepository _repository;
  const GetRecentSyncWindowDaysUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call() =>
      _repository.getRecentSyncWindowDays();
}

/// Persists the recent-sync window (days of history the capped surfaces pull).
@lazySingleton
class SetRecentSyncWindowDaysUseCase
    extends UseCase<Either<Failure, Unit>, int> {
  final AppSettingsRepository _repository;
  const SetRecentSyncWindowDaysUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(int input, {bool cached = false}) =>
      _repository.setRecentSyncWindowDays(input);
}

/// Persists the user's chosen app language code (`'en'`, `'hi'`, …), or `null`
/// to clear it. `LocaleCubit` calls this on every language switch.
@lazySingleton
class SetAppLocaleUseCase extends UseCase<Either<Failure, Unit>, String?> {
  final AppSettingsRepository _repository;
  const SetAppLocaleUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String? input, {bool cached = false}) =>
      _repository.setLocaleCode(input);
}

/// Persists the user's chosen theme mode (system / light / dark). The root
/// `ThemeCubit` calls this on every switch.
@lazySingleton
class SetThemeModeUseCase extends UseCase<Either<Failure, Unit>, AppThemeMode> {
  final AppSettingsRepository _repository;
  const SetThemeModeUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(AppThemeMode input,
          {bool cached = false}) =>
      _repository.setThemeMode(input);
}

// ── Note translation ─────────────────────────────────────────────────────────

/// The user's chosen translation target, or `null` if they've never picked one
/// — which is what makes the picker show on the first Translate tap only.
@lazySingleton
class GetTranslationLanguageUseCase
    extends NoParamsUseCase<Either<Failure, String?>> {
  final AppSettingsRepository _repository;
  const GetTranslationLanguageUseCase(this._repository);

  @override
  Future<Either<Failure, String?>> call() => _repository.getTranslationLanguage();
}

@lazySingleton
class SetTranslationLanguageUseCase
    extends UseCase<Either<Failure, Unit>, String?> {
  final AppSettingsRepository _repository;
  const SetTranslationLanguageUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String? input, {bool cached = false}) =>
      _repository.setTranslationLanguage(input);
}

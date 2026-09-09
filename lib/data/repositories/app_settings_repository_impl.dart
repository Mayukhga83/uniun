import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/theme/app_theme_mode.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/domain/repositories/app_settings_repository.dart';

@Injectable(as: AppSettingsRepository)
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final AppSettingsStore _store;

  AppSettingsRepositoryImpl(this._store);

  @override
  Future<Either<Failure, bool>> getNatarajCoachSeen() async {
    try {
      return Right(_store.natarajCoachSeen);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setNatarajCoachSeen(bool seen) async {
    try {
      await _store.setNatarajCoachSeen(seen);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> getAutoDeleteOldNotesDays() async {
    try {
      return Right(_store.autoDeleteOldNotesDays);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setAutoDeleteOldNotesDays(int? days) async {
    try {
      await _store.setAutoDeleteOldNotesDays(days);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getRecentSyncWindowDays() async {
    try {
      return Right(_store.recentSyncWindowDays);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setRecentSyncWindowDays(int days) async {
    try {
      await _store.setRecentSyncWindowDays(days);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLocaleCode(String? code) async {
    try {
      await _store.setLocaleCode(code);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getTranslationLanguage() async {
    try {
      return Right(_store.translationLanguage);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setTranslationLanguage(String? code) async {
    try {
      await _store.setTranslationLanguage(code);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setThemeMode(AppThemeMode mode) async {
    try {
      await _store.setThemeMode(mode);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}

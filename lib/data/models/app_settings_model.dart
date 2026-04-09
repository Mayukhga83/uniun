import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

part 'app_settings_model.g.dart';

/// Singleton settings row — always stored with id = 1.
/// Holds app-wide preferences that don't belong on a per-record model.
@Collection(ignore: {'copyWith'})
@Name('AppSettings')
class AppSettingsModel {
  /// Fixed primary key — there is always exactly one row.
  Id id = 1;

  /// The currently active AI model, or null if none is selected.
  @Enumerated(EnumType.name)
  AIModelId? activeModelId;
}

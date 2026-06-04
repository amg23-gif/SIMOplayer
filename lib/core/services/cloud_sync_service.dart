import '../../data/datasources/local/database.dart';

// خدمة المزامنة السحابية (معطّلة — تعمل فقط عند ربط Firebase مستقبلاً)
class CloudSyncService {
  final AppDatabase _db;
  CloudSyncService(this._db);

  bool get _canSync => false; // Firebase غير مُهيأ

  Future<void> syncAll() async {
    if (!_canSync) return;
  }

  Future<void> restoreFavorites() async {
    if (!_canSync) return;
  }

  Future<void> syncSources() async {
    if (!_canSync) return;
  }

  Future<void> syncSettings() async {
    if (!_canSync) return;
  }
}

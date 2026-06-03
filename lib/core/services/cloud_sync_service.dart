import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/database.dart';

// خدمة المزامنة السحابية مع Firestore
class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppDatabase _db;

  CloudSyncService(this._db);

  // الحصول على معرف المستخدم الحالي
  String? get _userId => _auth.currentUser?.uid;

  // هل المستخدم مسجل الدخول (وليس مجهولاً)
  bool get _canSync {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  // مزامنة جميع البيانات
  Future<void> syncAll() async {
    if (!_canSync || _userId == null) return;

    await Future.wait([
      _syncFavorites(),
      _syncSources(),
      _syncSettings(),
    ]);
  }

  // مزامنة المفضلة
  Future<void> _syncFavorites() async {
    if (!_canSync || _userId == null) return;

    final channels = await _db.getAllChannels();
    final favorites = channels.where((c) => c.isFavorite).toList();

    final favDoc =
        _firestore.collection(AppConstants.fsUsers).doc(_userId).collection(AppConstants.fsFavorites).doc('list');

    await favDoc.set({
      'items': favorites.map((c) => c.id).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // استعادة المفضلة من السحابة
  Future<void> restoreFavorites() async {
    if (!_canSync || _userId == null) return;

    final favDoc = await _firestore
        .collection(AppConstants.fsUsers)
        .doc(_userId)
        .collection(AppConstants.fsFavorites)
        .doc('list')
        .get();

    if (!favDoc.exists) return;

    final data = favDoc.data();
    final items = (data?['items'] as List?)?.cast<String>() ?? [];

    for (final channelId in items) {
      await _db.toggleFavorite(channelId, true);
    }
  }

  // مزامنة المصادر
  Future<void> _syncSources() async {
    if (!_canSync || _userId == null) return;

    final sourcesCollection = _firestore
        .collection(AppConstants.fsUsers)
        .doc(_userId)
        .collection(AppConstants.fsSources);

    final sources = await _db
        .watchSources()
        .first;

    final batch = _firestore.batch();
    for (final source in sources) {
      final docRef = sourcesCollection.doc(source.id);
      batch.set(docRef, {
        'id': source.id,
        'name': source.name,
        'type': source.type,
        'm3uUrl': source.m3uUrl,
        'serverUrl': source.serverUrl,
        'username': source.username,
        // لا نحفظ كلمة المرور في السحابة للأمان
        'epgUrl': source.epgUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // مزامنة الإعدادات
  Future<void> _syncSettings() async {
    if (!_canSync || _userId == null) return;

    final settingsDoc = _firestore
        .collection(AppConstants.fsUsers)
        .doc(_userId)
        .collection(AppConstants.fsSettings)
        .doc('preferences');

    final theme = await _db.getSetting(AppConstants.kThemeMode) ?? 'dark';
    final locale = await _db.getSetting(AppConstants.kLocale) ?? 'ar';

    await settingsDoc.set({
      'themeMode': theme,
      'locale': locale,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // استعادة الإعدادات من السحابة
  Future<void> restoreSettings() async {
    if (!_canSync || _userId == null) return;

    final settingsDoc = await _firestore
        .collection(AppConstants.fsUsers)
        .doc(_userId)
        .collection(AppConstants.fsSettings)
        .doc('preferences')
        .get();

    if (!settingsDoc.exists) return;

    final data = settingsDoc.data();
    if (data == null) return;

    if (data['themeMode'] != null) {
      await _db.setSetting(AppConstants.kThemeMode, data['themeMode']);
    }
    if (data['locale'] != null) {
      await _db.setSetting(AppConstants.kLocale, data['locale']);
    }
  }

  // مزامنة سجل المشاهدة
  Future<void> syncWatchHistory(String profileId) async {
    if (!_canSync || _userId == null) return;

    final history = await _db.watchHistory(profileId: profileId, limit: 50).first;

    final histDoc = _firestore
        .collection(AppConstants.fsUsers)
        .doc(_userId)
        .collection(AppConstants.fsHistory)
        .doc(profileId);

    await histDoc.set({
      'items': history.map((h) => {
        'channelId': h.channelId,
        'channelName': h.channelName,
        'channelLogo': h.channelLogo,
        'watchedAt': h.watchedAt.millisecondsSinceEpoch,
        'stopPositionSeconds': h.stopPositionSeconds,
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

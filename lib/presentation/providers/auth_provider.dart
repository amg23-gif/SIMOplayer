import 'package:flutter_riverpod/flutter_riverpod.dart';

// نموذج المستخدم المبسّط (بدون Firebase)
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.isAnonymous = true,
  });
}

// مزود المستخدم الحالي (دائماً مجهول)
final currentUserProvider = Provider<AppUser?>((ref) {
  return const AppUser(uid: 'local', isAnonymous: true);
});

// خدمة المصادقة المبسّطة (بدون Firebase)
class AuthService {
  Future<void> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // ستُفعَّل مستقبلاً عند إعداد Firebase
  Future<void> signInWithGoogle() async {
    throw Exception('سجّل الدخول كضيف الآن — ميزة Google متاحة قريباً');
  }

  Future<void> signInWithApple() async {
    throw Exception('سجّل الدخول كضيف الآن — ميزة Apple متاحة قريباً');
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  bool get isSignedIn => true;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

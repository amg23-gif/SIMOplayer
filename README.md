# SIMO Player — مشغل IPTV الاحترافي

<div dir="rtl">

## نظرة عامة

**SIMO Player** هو مشغل IPTV احترافي مفتوح المصدر مبني بـ Flutter، يدعم:
- 📱 Android (هاتف وتابلت)
- 📺 Android TV
- 🍎 iOS

---

## الميزات الرئيسية

| الميزة | الحالة |
|--------|--------|
| دعم M3U (رابط أو ملف) | ✅ |
| دعم Xtream Codes API | ✅ |
| دليل البرامج EPG (XMLTV) | ✅ |
| مشغل HLS/MPEG-TS | ✅ |
| مبدل المصادر التلقائي | ✅ |
| فاحص القنوات الدوري | ✅ |
| ملفات شخصية متعددة | ✅ |
| مزامنة سحابية (Firebase) | ✅ |
| الإعداد عن بُعد (QR Code) | ✅ |
| غرفة مشاهدة جماعية | ✅ |
| صورة داخل صورة (PiP) | ✅ |
| التسجيل المحلي والسحابي | ✅ |
| TimeShift (إيقاف البث المباشر) | ✅ |
| البحث الصوتي | ✅ |
| ثيمات متعددة (داكن/فاتح/OLED) | ✅ |
| دعم RTL عربي كامل | ✅ |
| وضع الموزعين (Rebranding) | ✅ |

---

## المتطلبات

- Flutter SDK >= 3.10.0
- Dart >= 3.0.0
- Android Studio أو Xcode (للبناء)
- حساب Firebase (مجاني يكفي)

---

## خطوات التشغيل

### 1. استنساخ المشروع
```bash
# فك ضغط ملف ZIP أو استنسخ من المصدر
```

### 2. تثبيت الحزم
```bash
flutter pub get
```

### 3. إعداد Firebase

**أ. إنشاء مشروع Firebase:**
1. اذهب إلى [console.firebase.google.com](https://console.firebase.google.com)
2. أنشئ مشروعاً جديداً باسم `simo-player`
3. فعّل الخدمات التالية:
   - **Authentication** (Google + Apple)
   - **Cloud Firestore**
   - **Firebase Storage**
   - **Realtime Database**

**ب. ربط Firebase بالتطبيق:**
```bash
# ثبّت FlutterFire CLI
dart pub global activate flutterfire_cli

# اربط التطبيق بمشروع Firebase
flutterfire configure --project=your-firebase-project-id
```
سيُولّد هذا الأمر ملف `lib/firebase_options.dart` الصحيح تلقائياً.

**ج. للأندرويد:** ضع ملف `google-services.json` في مجلد `android/app/`

**د. للـ iOS:** ضع ملف `GoogleService-Info.plist` في مجلد `ios/Runner/`

### 4. توليد كود Drift (قاعدة البيانات)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. تشغيل التطبيق
```bash
# للهاتف
flutter run

# للـ TV
flutter run -d <android-tv-device-id>

# للإصدار
flutter build apk --release
flutter build appbundle --release
flutter build ipa --release
```

---

## هيكل المشروع

```
lib/
├── main.dart                          # نقطة الدخول
├── firebase_options.dart              # إعدادات Firebase
│
├── core/                              # طبقة البنية التحتية
│   ├── constants/app_constants.dart   # الثوابت
│   ├── theme/app_theme.dart           # الثيمات
│   ├── router/app_router.dart         # التوجيه
│   ├── localization/                  # الترجمة (AR/EN)
│   ├── utils/
│   │   ├── m3u_parser.dart            # تحليل M3U في Isolate
│   │   ├── epg_parser.dart            # تحليل XMLTV في Isolate
│   │   └── channel_checker.dart      # فاحص القنوات
│   └── services/
│       └── cloud_sync_service.dart    # المزامنة السحابية
│
├── data/                              # طبقة البيانات
│   └── datasources/local/
│       ├── database.dart              # Drift DB (SQLite)
│       └── database.g.dart            # كود مولّد
│
├── domain/                            # طبقة المجال
│   └── entities/
│       ├── channel.dart
│       ├── epg_program.dart
│       ├── source.dart
│       ├── profile.dart
│       └── watch_history.dart
│
└── presentation/                      # طبقة العرض
    ├── providers/                     # Riverpod Providers
    │   ├── auth_provider.dart
    │   ├── settings_provider.dart
    │   ├── channels_provider.dart
    │   └── player_provider.dart
    │
    ├── screens/                       # الشاشات
    │   ├── splash/                    # شاشة البداية
    │   ├── auth/                      # تسجيل الدخول
    │   ├── profile/                   # اختيار الملف الشخصي
    │   ├── home/                      # الشاشة الرئيسية
    │   ├── player/                    # المشغل
    │   ├── channels/                  # قائمة القنوات + إضافة مصدر
    │   ├── search/                    # البحث (+ صوتي)
    │   ├── epg/                       # دليل البرامج
    │   ├── recordings/                # التسجيلات
    │   ├── watch_party/               # غرفة المشاهدة الجماعية
    │   └── settings/                  # الإعدادات + الإعداد عن بُعد
    │
    └── widgets/                       # ودجت قابلة لإعادة الاستخدام
        ├── channel_card.dart          # بطاقة القناة
        ├── app_bottom_nav.dart        # شريط التنقل
        ├── continue_watching_section.dart
        └── shimmer_loading.dart

android/
├── app/
│   ├── build.gradle                   # إعدادات البناء
│   └── src/main/AndroidManifest.xml   # الصلاحيات + TV دعم
└── build.gradle

ios/
└── Runner/
    └── Info.plist                     # صلاحيات iOS

assets/
└── config/
    └── rebrand.json                   # إعدادات الموزعين
```

---

## إعداد Firebase Firestore (قواعد الأمان)

انسخ هذه القواعد في Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /watch_parties/{partyId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## إعداد Firebase Realtime Database (قواعد الأمان)

```json
{
  "rules": {
    "watch_parties": {
      "$partyId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "remote_setup": {
      "$code": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## إعداد تسجيل الدخول بـ Google

1. في Firebase Console > Authentication > Sign-in method
2. فعّل Google
3. أضف SHA-1 fingerprint للأندرويد:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## وضع الموزعين (Rebranding)

عدّل ملف `assets/config/rebrand.json`:
```json
{
  "enabled": true,
  "appName": "اسم تطبيقك",
  "primaryColor": "#FF5722",
  "accentColor": "#FFC107"
}
```

---

## الأسئلة الشائعة

**س: هل يدعم التطبيق بث HTTPS؟**
ج: نعم، يدعم HTTP و HTTPS و HLS وجميع البروتوكولات المدعومة من video_player.

**س: كيف أضيف رابط IPTV؟**
ج: من الشاشة الرئيسية > الإعدادات > إضافة مصدر > أدخل رابط M3U أو بيانات Xtream.

**س: هل يعمل التطبيق بدون إنترنت؟**
ج: نعم، القنوات المحفوظة محلياً ستظهر لكن البث يتطلب اتصالاً.

**س: كيف أفعّل الإعداد عن بُعد؟**
ج: من التلفزيون: الإعدادات > الإعداد عن بُعد. من الهاتف: امسح رمز QR الظاهر.

---

## المساهمة

نرحب بأي مساهمات! يرجى:
1. عمل Fork للمشروع
2. إنشاء Branch جديد
3. تقديم Pull Request

---

## الترخيص

MIT License — استخدام حر مفتوح المصدر.

---

**صُنع بـ ❤️ لمجتمع IPTV العربي**

</div>

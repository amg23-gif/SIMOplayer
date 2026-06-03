import 'package:equatable/equatable.dart';

// كيان القناة الرئيسي
class Channel extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String category;
  final String? group;
  final String? language;
  final String? country;
  final String? tvgId;         // معرف EPG
  final String? tvgName;       // اسم EPG
  final List<String> streamUrls; // روابط البث المتعددة
  final bool isFavorite;
  final bool isAvailable;      // نتيجة فحص القناة
  final DateTime? lastChecked; // آخر فحص
  final int? currentSourceIndex; // المصدر الحالي

  const Channel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.category,
    this.group,
    this.language,
    this.country,
    this.tvgId,
    this.tvgName,
    required this.streamUrls,
    this.isFavorite = false,
    this.isAvailable = true,
    this.lastChecked,
    this.currentSourceIndex = 0,
  });

  // الحصول على رابط البث الحالي
  String? get currentStreamUrl {
    if (streamUrls.isEmpty) return null;
    final index = currentSourceIndex ?? 0;
    if (index >= streamUrls.length) return streamUrls.first;
    return streamUrls[index];
  }

  // الانتقال للمصدر التالي
  Channel withNextSource() {
    final nextIndex = ((currentSourceIndex ?? 0) + 1) % streamUrls.length;
    return copyWith(currentSourceIndex: nextIndex);
  }

  Channel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? category,
    String? group,
    String? language,
    String? country,
    String? tvgId,
    String? tvgName,
    List<String>? streamUrls,
    bool? isFavorite,
    bool? isAvailable,
    DateTime? lastChecked,
    int? currentSourceIndex,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      group: group ?? this.group,
      language: language ?? this.language,
      country: country ?? this.country,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      streamUrls: streamUrls ?? this.streamUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailable: isAvailable ?? this.isAvailable,
      lastChecked: lastChecked ?? this.lastChecked,
      currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        logoUrl,
        category,
        streamUrls,
        isFavorite,
        isAvailable,
        currentSourceIndex,
      ];
}

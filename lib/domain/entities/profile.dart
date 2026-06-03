import 'package:equatable/equatable.dart';

// كيان الملف الشخصي
class Profile extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? avatarEmoji;
  final bool isDefault;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.avatarEmoji,
    this.isDefault = false,
    required this.createdAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? avatarEmoji,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, isDefault];
}

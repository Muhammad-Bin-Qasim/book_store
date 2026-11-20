import '../core/app_utils.dart';

enum UserRole { user, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.addresses = const <Map<String, dynamic>>[],
    this.paymentMethods = const <Map<String, dynamic>>[],
    this.disabled = false,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<Map<String, dynamic>> addresses;
  final List<Map<String, dynamic>> paymentMethods;
  final bool disabled;
  final DateTime? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> map, {String? uid}) {
    final roleName = map['role'] as String?;
    return AppUser(
      uid: uid ?? map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (value) => value.name == roleName,
        orElse: () => UserRole.user,
      ),
      addresses: _mapList(map['addresses']),
      paymentMethods: _mapList(map['paymentMethods']),
      disabled: map['disabled'] == true,
      createdAt: AppUtils.dateTimeFromValue(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role.name,
        'addresses': addresses,
        'paymentMethods': paymentMethods,
        'disabled': disabled,
        'createdAt': createdAt,
      };

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! Iterable) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    List<Map<String, dynamic>>? addresses,
    List<Map<String, dynamic>>? paymentMethods,
    bool? disabled,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      disabled: disabled ?? this.disabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

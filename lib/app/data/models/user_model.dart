/// مدل User — قرارداد Formatter::user بک‌اند (camelCase flat).
class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.permissions = const [],
    required this.walletBalance,
    this.createdAt,
    this.isBlocked = false,
  });

  final String id;
  final String phone;
  final String name;
  final String role;
  final List<String> permissions;
  final int walletBalance;
  final String? createdAt;
  final bool isBlocked;

  factory UserModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return UserModel(
      id: '${m['id'] ?? ''}',
      phone: '${m['phone'] ?? ''}',
      name: '${m['name'] ?? ''}',
      role: '${m['role'] ?? 'customer'}',
      permissions: (m['permissions'] as List?)?.map((e) => '$e').toList() ?? const [],
      walletBalance: _asInt(m['walletBalance']),
      createdAt: m['createdAt']?.toString(),
      isBlocked: m['isBlocked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'role': role,
        'permissions': permissions,
        'walletBalance': walletBalance,
        'createdAt': createdAt,
        'isBlocked': isBlocked,
      };

  static int _asInt(dynamic v) =>
      v is int ? v : (int.tryParse('$v') ?? 0);
}

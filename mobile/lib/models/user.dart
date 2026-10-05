import 'common.dart';

enum UserRole { customer, staff, admin }

extension UserRoleX on UserRole {
  String get apiName => switch (this) { UserRole.customer => 'Customer', UserRole.staff => 'Staff', UserRole.admin => 'Admin' };

  String get label => apiName;

  bool get isStaffOrAdmin => this == UserRole.staff || this == UserRole.admin;
}

UserRole parseRole(Object? value) => enumByName(UserRole.values, value, UserRole.customer);

class AppUser {
  const AppUser({required this.id, required this.fullName, required this.email, this.phoneNumber, required this.role});

  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final UserRole role;

  factory AppUser.fromJson(Json json) => AppUser(
        id: toInt(json['id']),
        fullName: '${json['fullName']}',
        email: '${json['email']}',
        phoneNumber: json['phoneNumber'] as String?,
        role: parseRole(json['role']),
      );
}

class AuthResult {
  const AuthResult(this.accessToken, this.user);

  final String accessToken;
  final AppUser user;

  factory AuthResult.fromJson(Json json) => AuthResult('${json['accessToken']}', AppUser.fromJson(json['user'] as Json));
}

class Address {
  const Address({
    required this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
    required this.isDefault,
  });

  final int id;
  final String recipientName;
  final String phoneNumber;
  final String addressLine;
  final String ward;
  final String district;
  final String city;
  final bool isDefault;

  String get fullAddress => [addressLine, ward, district, city].where((s) => s.isNotEmpty).join(', ');

  factory Address.fromJson(Json json) => Address(
        id: toInt(json['id']),
        recipientName: '${json['recipientName']}',
        phoneNumber: '${json['phoneNumber']}',
        addressLine: '${json['addressLine']}',
        ward: '${json['ward']}',
        district: '${json['district']}',
        city: '${json['city']}',
        isDefault: json['isDefault'] == true,
      );
}

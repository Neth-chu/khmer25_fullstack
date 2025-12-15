import 'package:flutter/foundation.dart';

class AppUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const AppUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }

  String get displayName {
    if (username.isNotEmpty) return username;
    final full = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : 'Anonymous User';
  }

  String get emailDisplay => email.isNotEmpty ? email : 'No email provided';
  String get phoneDisplay => phone.isNotEmpty ? phone : 'Not Provided';
}

class AuthStore {
  static final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  static void setUser(AppUser? user) {
    currentUser.value = user;
  }

  static void clear() {
    currentUser.value = null;
  }

  static void logout() {
    clear();
  }
}

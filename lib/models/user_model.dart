enum UserRole {
  student,
  admin,
  institution,
}

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.index,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      fullName: map['fullName'],
      role: UserRole.values[map['role'] ?? 0],
      profileImageUrl: map['profileImageUrl'],
    );
  }
}

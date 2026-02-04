enum UserRole {
  student,
  admin,
}

enum SubscriptionPlan {
  free,
  pro,
}

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final SubscriptionPlan plan;
  final String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.plan = SubscriptionPlan.free,
    this.profileImageUrl,
    this.recoveryPin,
  });

  final String? recoveryPin;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.index,
      'plan': plan.index,
      'profileImageUrl': profileImageUrl,
      'recoveryPin': recoveryPin,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      fullName: map['fullName'],
      role: UserRole.values[map['role'] ?? 0],
      plan: SubscriptionPlan.values[map['plan'] ?? 0],
      profileImageUrl: map['profileImageUrl'],
      recoveryPin: map['recoveryPin'],
    );
  }
}

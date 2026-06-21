class UserModel {
  final int id;
  final String username;
  final String email;
  final String? avatar;
  final String status;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    required this.status,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      username: json['username'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      status: json['status'] as String? ?? 'offline',
      fcmToken: json['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'status': status,
      'fcmToken': fcmToken,
    };
  }
}

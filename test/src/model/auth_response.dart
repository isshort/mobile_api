final class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.expiresUtc,
    this.userId,
    this.email,
    this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'] as String,
    expiresUtc: json['expiresUtc'] as String?,
    userId: json['userId'] as String?,
    email: json['email'] as String?,
    roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );
  final String accessToken;
  final String? expiresUtc;
  final String? userId;
  final String? email;
  final List<String>? roles;
}

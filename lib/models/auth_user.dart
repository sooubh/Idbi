class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
}

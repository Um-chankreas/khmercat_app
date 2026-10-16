class User {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profilePicture;
  final String? coverPicture;
  final String? bio;

  /// Can approve restaurants and review reports (Menu → Admin).
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profilePicture,
    this.coverPicture,
    this.bio,
    this.isAdmin = false,
  });
}

class User {
  final String name;
  final String photo;
  final String phone;
  final String email;
  final String gender; // 'Male' | 'Female' | 'Other'

  User({
    required this.name,
    required this.photo,
    required this.phone,
    required this.email,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photo': photo,
      'phone': phone,
      'email': email,
      'gender': gender,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      photo: json['photo'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? 'Male',
    );
  }
}

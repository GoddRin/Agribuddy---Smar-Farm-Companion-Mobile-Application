class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String farmName;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.farmName,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'username': username,
    'email': email, 'password': password, 'farmName': farmName,
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], name: j['name'],
    username: j['username'] ?? j['email'] ?? '',
    email: j['email'] ?? '',
    password: j['password'], farmName: j['farmName'],
  );
}

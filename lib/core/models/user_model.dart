class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String farmName;
  final String? googleId;
  final String? phoneNumber;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.farmName,
    this.googleId,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'username': username,
    'email': email, 'password': password, 'farmName': farmName,
    'googleId': googleId, 'phoneNumber': phoneNumber,
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: j['name']?.toString() ?? 'Farmer',
    username: (j['username'] ?? j['email'] ?? 'farmer').toString(),
    email: (j['email'] ?? '').toString(),
    password: (j['password'] ?? '').toString(),
    farmName: (j['farmName'] ?? 'Common Farm').toString(),
    googleId: j['googleId']?.toString(),
    phoneNumber: j['phoneNumber']?.toString(),
  );
}

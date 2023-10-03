import 'package:hive/hive.dart';

class User {
  final String username;
  final String password;

  User({
    required this.username,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class UserAdapter extends TypeAdapter<User> {
  @override
  int get typeId => 0;

  @override
  User read(BinaryReader reader) {
    return User(
      username: reader.read(),
      password: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(obj.username);
    writer.write(obj.password);
  }
}

class UserRepository {
  static const database = {0: "Alex", 1: "Barry", 2: "Connan", 3: "Garry"};

  String usernameById(int userId) {
    return database[userId] ?? "Not found";
  }
}

class UserViewModel {
  final int userId;
  final UserRepository userRepository;

  UserViewModel(this.userId, this.userRepository);

  void sayHello() {
    final username = userRepository.usernameById(userId);
    print("Hello, $username");
  }
}

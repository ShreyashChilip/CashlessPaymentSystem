class Student {
  final String id;
  final String name;
  final String email;
  final String walletAddress;
  final double walletBalance;
  final double walletLimit;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.walletAddress,
    this.walletBalance = 0.0,
    this.walletLimit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'walletAddress': walletAddress,
      'walletBalance': walletBalance,
      'walletLimit': walletLimit,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      walletAddress: map['walletAddress'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      walletLimit: (map['walletLimit'] ?? 0.0).toDouble(),
    );
  }
}

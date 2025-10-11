class Parent {
  final String id;
  final String username;
  final String contact;
  final List<String> studentIds;

  Parent({
    required this.id,
    required this.username,
    required this.contact,
    required this.studentIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'contact': contact,
      'studentIds': studentIds,
    };
  }
}

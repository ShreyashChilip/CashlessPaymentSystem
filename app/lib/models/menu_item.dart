class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  int quantity;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 0,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      quantity: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }
}
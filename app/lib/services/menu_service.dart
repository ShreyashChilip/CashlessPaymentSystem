import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> populateMenu() async {
    // Create a batch for multiple writes
    final batch = _db.batch();

    List<MenuItem> menuItems = [
      MenuItem(id: 'C1', name: 'SUFIYAN Milk (300ml)', price: 15, category: 'healthy'),
      MenuItem(id: 'C2', name: 'Boiled Egg (1 pc)', price: 8, category: 'healthy'),
      MenuItem(id: 'C3', name: 'Ginger Tea (small)', price: 5, category: 'mid'),
      MenuItem(id: 'C4', name: 'Ginger Tea (big)', price: 10, category: 'mid'),
      MenuItem(id: 'C5', name: 'Coffee (small)', price: 10, category: 'mid'),
      MenuItem(id: 'C6', name: 'Coffee (big)', price: 20, category: 'mid'),
      MenuItem(id: 'C7', name: 'Omelette (1 egg)', price: 12, category: 'healthy'),
      MenuItem(id: 'C8', name: 'Omelette (2 eggs)', price: 22, category: 'healthy'),
      MenuItem(id: 'C9', name: 'Bread Omelette (1 egg)', price: 15, category: 'mid'),
      MenuItem(id: 'C10', name: 'Bread Omelette (2 eggs)', price: 25, category: 'mid'),
      MenuItem(id: 'C11', name: 'Banana', price: 5, category: 'healthy'),
      MenuItem(id: 'C12', name: 'Corn Flakes with milk', price: 25, category: 'healthy'),
      MenuItem(id: 'C13', name: 'Fruit Salad', price: 25, category: 'healthy'),
      MenuItem(id: 'C14', name: 'Samosa (4pc)', price: 20, category: 'junk'),
      MenuItem(id: 'C15', name: 'French Fries', price: 30, category: 'junk'),
      MenuItem(id: 'C16', name: 'Pav Bhaji', price: 25, category: 'junk'),
      MenuItem(id: 'C17', name: 'Maggi (Veg)', price: 20, category: 'junk'),
      MenuItem(id: 'C18', name: 'Egg Maggi', price: 25, category: 'mid'),
      MenuItem(id: 'C19', name: 'Chicken Lollipop', price: 60, category: 'junk'),
      MenuItem(id: 'C20', name: 'Veg Roll', price: 30, category: 'junk'),
      MenuItem(id: 'C21', name: 'Paneer Roll', price: 40, category: 'mid'),
      MenuItem(id: 'C22', name: 'Chicken Roll', price: 45, category: 'junk'),
      MenuItem(id: 'C23', name: 'Veg Chowmein', price: 25, category: 'junk'),
      MenuItem(id: 'C24', name: 'Chicken Chowmein', price: 40, category: 'junk'),
    ];

    // Add all operations to batch
    for (var item in menuItems) {
      final docRef = _db.collection('menu_items').doc(item.id);
      batch.set(docRef, item.toMap(), SetOptions(merge: true));
    }

    // Commit the batch
    try {
      await batch.commit();
      print('Menu items successfully populated');
    } catch (e) {
      print('Error populating menu items: $e');
      rethrow;
    }
  }

  Future<List<MenuItem>> getMenuItems() async {
    try {
      final snapshot = await _db.collection('menu_items').get();
      return snapshot.docs
          .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }
}
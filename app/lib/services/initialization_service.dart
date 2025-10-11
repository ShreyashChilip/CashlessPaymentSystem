import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitializationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MenuService _menuService = MenuService();

  Future<void> initializeApp() async {
    // Check if menu has been populated
    final hasMenuBeenPopulated = await _checkIfMenuExists();
    
    if (!hasMenuBeenPopulated) {
      print('Populating menu for first time...');
      await _menuService.populateMenu();
      print('Menu population complete');
    }
  }

  Future<bool> _checkIfMenuExists() async {
    try {
      final menuSnapshot = await _db.collection('menu_items').limit(1).get();
      return menuSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking menu existence: $e');
      return false;
    }
  }
}
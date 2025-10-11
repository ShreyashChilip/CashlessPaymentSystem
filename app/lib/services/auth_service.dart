import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'blockchain_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BlockchainService _blockchainService = BlockchainService();

  Future<Map<String, dynamic>?> register(
    String username, 
    String password, 
    String role,
    Map<String, dynamic> additionalData
  ) async {
    try {
      // Check if username already exists
      final userDoc = await _firestore.collection('users').doc(username).get();
      if (userDoc.exists) {
        return null;
      }

      // Create user data with default balance for students
      final userData = {
        'username': username,
        'password': password,
        'role': role,
        ...additionalData,
      };

      // Add default balance if user is a student
      if (role == 'student') {
        if (additionalData['privateKey'] == null || 
            additionalData['walletAddress'] == null) {
          throw Exception('Private key and wallet address are required');
        }

        // Verify wallet balance through API
        final balance = await _blockchainService.getWalletBalance(
          additionalData['walletAddress']
        );

        userData.addAll({
          'walletAddress': additionalData['walletAddress'],
          'privateKey': additionalData['privateKey'], // Store encrypted
          'walletBalance': balance,
          'walletLimit': additionalData['walletLimit'] ?? 100.0,
          'rfidUID': additionalData['rfidUID'],
        });
      }

      // Store user in Firestore
      await _firestore.collection('users').doc(username).set(userData);

      // Store current user in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', username);

      return userData;
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
  }

  Future<UserModel?> login(String username, String password) async {
    try {
      final userDoc = await _firestore.collection('users').doc(username).get();
      if (userDoc.exists && userDoc.data()?['password'] == password) {
        // Store current user in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', username);
        
        // Convert map to UserModel
        return UserModel.fromMap(userDoc.data()!, username);
      }
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('currentUser');
      if (currentUsername != null) {
        final userDoc = await _firestore.collection('users').doc(currentUsername).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, currentUsername);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForParent(String parentUsername) async {
    try {
      final parentDoc = await _firestore.collection('users').doc(parentUsername).get();
      if (!parentDoc.exists || parentDoc.data()?['role'] != 'parent') {
        return [];
      }

      final List<String> studentIds = List<String>.from(parentDoc.data()?['studentIds'] ?? []);
      final students = await Future.wait(
        studentIds.map((id) => _firestore.collection('users').doc(id).get())
      );

      return students
          .where((doc) => doc.exists)
          .map((doc) => doc.data()!)
          .toList();
    } catch (e) {
      print('Error getting students for parent: $e');
      return [];
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> updateWalletLimit(String username, double newLimit) async {
    try {
      await _firestore.collection('users').doc(username).update({
        'walletLimit': newLimit,
      });
      return true;
    } catch (e) {
      print('Error updating wallet limit: $e');
      return false;
    }
  }

  Future<bool> updateWalletSettings(String? studentId, double newLimit, double newBalance) async {
    try {
      if (studentId == null || studentId.isEmpty) {
        print('Error: Invalid student ID');
        return false;
      }

      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        print('Error: Student not found');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(studentId)
          .update({
            'walletLimit': newLimit,
            'walletBalance': newBalance,
          });
      return true;
    } catch (e) {
      print('Error updating wallet settings: $e');
      return false;
    }
  }

  Future<bool> processVendorTransaction(String studentWalletAddress, double amount) async {
    try {
      // Get current user (vendor)
      final currentUser = await getCurrentUser();
      if (currentUser == null || currentUser.role != 'vendor') {
        return false;
      }

      // Find student by wallet address
      final studentQuery = await _firestore
          .collection('users')
          .where('walletAddress', isEqualTo: studentWalletAddress)
          .where('role', isEqualTo: 'student')
          .get();

      if (studentQuery.docs.isEmpty) {
        return false;
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();
      
      // Check student's balance and limit
      final currentBalance = await _blockchainService.getWalletBalance(studentWalletAddress) ?? 0.0;
      final walletLimit = studentData['walletLimit'] ?? 0.0;

      if (amount > walletLimit || amount > currentBalance) {
        return false;
      }

      // Update student's balance
      await _firestore.collection('users').doc(studentDoc.id).update({
        'walletBalance': currentBalance - amount,
      });

      // Update vendor's balance
      await _firestore.collection('users').doc(currentUser.id).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('Error processing transaction: $e');
      return false;
    }
  }

  Future<List<MenuItem>> getMenuItems() async {
    try {
      final menuSnapshot = await _firestore.collection('menu_items').get();
      return menuSnapshot.docs
          .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading menu items: $e');
      return [];
    }
  }

  void startRFIDListener({required Function(String) onRFIDDetected}) {
    // For now, we'll simulate RFID detection after 3 seconds
    // In a real app, this would interface with actual RFID hardware
    Future.delayed(Duration(seconds: 3), () {
      // Simulate RFID detection
      onRFIDDetected('student123'); // Replace with actual student ID
    });
  }

  Future<String?> getWalletAddressByRFID(String cardUID) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('rfidUID', isEqualTo: cardUID)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No student found with RFID UID: $cardUID');
        return null;
      }

      return userQuery.docs.first.data()['walletAddress'];
    } catch (e) {
      print('Error getting wallet address by RFID: $e');
      return null;
    }
  }

  Future<bool> processRFIDTransaction(String cardUID, double amount) async {
    try {
      print('Debug: Starting RFID transaction for card: $cardUID with amount: $amount');
      
      final studentQuery = await _firestore
          .collection('users')
          .where('rfidUID', isEqualTo: cardUID)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        print('Debug: No student found with RFID: $cardUID');
        return false;
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();
      
      print('Debug: Found student: ${studentDoc.id}');
      print('Debug: Student wallet address: ${studentData['walletAddress']}');
      print('Debug: Student private key: ${studentData['privateKey']}');

      // Get real-time balance
      final currentBalance = await _blockchainService.getWalletBalance(
        studentData['walletAddress']
      );
      print('Debug: Current balance: $currentBalance');

      if (amount > currentBalance) {
        print('Debug: Insufficient balance. Required: $amount, Available: $currentBalance');
        return false;
      }

      final walletLimit = studentData['walletLimit'] ?? 0.0;
      if (amount > walletLimit) {
        print('Debug: Amount exceeds wallet limit. Required: $amount, Limit: $walletLimit');
        return false;
      }

      // Get current vendor
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        print('Debug: No vendor found');
        return false;
      }

      final vendorDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get();

      if (!vendorDoc.exists) {
        print('Debug: Vendor document not found');
        return false;
      }

      print('Debug: Vendor wallet address: ${vendorDoc.data()?['walletAddress']}');

      // Parse private key correctly
      List<int> payerSecretArray;
      try {
        payerSecretArray = studentData['privateKey'].toString().split(',').map((s) => int.parse(s.trim())).toList();
        print('Debug: Parsed private key array length: ${payerSecretArray.length}');
      } catch (e) {
        print('Debug: Error parsing private key: $e');
        return false;
      }

      // Perform blockchain transaction
      print('Debug: Initiating blockchain transfer');
      final transferSuccess = await _blockchainService.transferTokens(
        payerSecretArray: payerSecretArray,
        recipientWalletAddress: vendorDoc.data()?['walletAddress'],
        amount: amount,
      );

      print('Debug: Transfer result: $transferSuccess');

      if (transferSuccess) {
        // Save transaction record
        final transaction = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          studentId: studentDoc.id,
          vendorId: currentUser.id,
          vendorName: vendorDoc.data()?['username'] ?? 'Unknown Vendor',
          amount: amount,
          timestamp: DateTime.now(),
          items: [], // Add items if available
        );

        await saveTransaction(transaction);
        print('Debug: Transaction saved successfully');
      }

      return transferSuccess;
    } catch (e) {
      print('Error processing RFID transaction: $e');
      return false;
    }
  }

  Future<String?> checkRFIDStatus() async {
    try {
      // Replace with your actual API endpoint
      final response = await http.get(Uri.parse('https://rfid.testersquad.me/rfid-status'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if card is detected
        if (data['cardDetected'] == true && data['cardUID'] != null) {
          final cardUID = data['cardUID'];
          
          // Get wallet address for this card UID
          final userQuery = await _firestore
              .collection('users')
              .where('rfidUID', isEqualTo: cardUID)
              .where('role', isEqualTo: 'student')
              .limit(1)
              .get();

          if (userQuery.docs.isEmpty) {
            print('Debug: No user found for card UID: $cardUID');
            return null;
          }

          final userData = userQuery.docs.first.data();
          final walletAddress = userData['walletAddress'];
          print('Debug: Found wallet address: $walletAddress for card UID: $cardUID');
          
          return cardUID;
        }
        
        print('Debug: Card not detected or UID is null');
        return null;
      }
      
      print('Debug: API request failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Debug: Error checking RFID status: $e');
      return null;
    }
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      print('Debug: Starting transaction save');
      
      // Create the transaction document
      final transactionRef = _firestore.collection('transactions').doc();
      
      // Prepare transaction data
      final transactionData = transaction.toMap();
      
      // Add transaction ID and creation timestamp
      transactionData['id'] = transactionRef.id;
      transactionData['createdAt'] = FieldValue.serverTimestamp();
      
      print('Debug: Saving transaction data: $transactionData');

      // Save the transaction
      await transactionRef.set(transactionData);
      
      print('Debug: Transaction saved successfully with ID: ${transactionRef.id}');

    } catch (e) {
      print('Error in saveTransaction: $e');
      throw Exception('Failed to save transaction: $e');
    }
  }

  Future<List<TransactionModel>> getStudentTransactions(String studentId) async {
    try {
      print('Debug: Fetching transactions for student: $studentId');
      
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('studentId', isEqualTo: studentId)
          .get();

      print('Debug: Found ${querySnapshot.docs.length} transactions');

      List<TransactionModel> transactions = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          transactions.add(TransactionModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          print('Debug: Error parsing transaction ${doc.id}: $e');
          print('Debug: Document data: ${doc.data()}');
          // Continue processing other transactions
          continue;
        }
      }

      // Sort by timestamp
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['username'] = doc.id; // Add document ID as username
        return data;
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStudentData(String username) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(username)
          .get();

      if (!docSnapshot.exists) {
        print('Debug: Student not found: $username');
        return null;
      }

      final data = docSnapshot.data()!;
      data['username'] = username; // Add document ID as username
      return data;
    } catch (e) {
      print('Error getting student data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentByRFID(String cardUID) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('rfidUID', isEqualTo: cardUID)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('Debug: No student found for card UID: $cardUID');
        return null;
      }

      final studentDoc = querySnapshot.docs.first;
      final data = studentDoc.data();
      data['username'] = studentDoc.id; // Add document ID as username
      
      print('Debug: Found student: ${studentDoc.id} for card: $cardUID');
      return data;
    } catch (e) {
      print('Error getting student by RFID: $e');
      return null;
    }
  }
}
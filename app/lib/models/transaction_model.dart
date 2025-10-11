import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String studentId;
  final String vendorId;
  final String vendorName;
  final double amount;
  final DateTime timestamp;
  final List<TransactionItem> items;
  final String status;
  final String type;

  TransactionModel({
    required this.id,
    required this.studentId,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    required this.timestamp,
    required this.items,
    this.status = 'completed',
    this.type = 'purchase',
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle different timestamp formats
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        print('Warning: Invalid timestamp format: $timestamp');
        return DateTime.now(); // Fallback to current time
      }
    }

    try {
      return TransactionModel(
        id: id,
        studentId: map['studentId'] ?? '',
        vendorId: map['vendorId'] ?? '',
        vendorName: map['vendorName'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        timestamp: parseTimestamp(map['timestamp']),
        status: map['status'] ?? 'completed',
        type: map['type'] ?? 'purchase',
        items: List<TransactionItem>.from(
          (map['items'] ?? []).map((item) => TransactionItem.fromMap(item)),
        ),
      );
    } catch (e) {
      print('Error parsing transaction $id: $e');
      print('Document data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(), // Always use server timestamp when saving
      'status': status,
      'type': type,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  DateTime get sortableDate {
    return timestamp;
  }

  bool hasCategory(String category) {
    return items.any((item) => item.category.toLowerCase() == category.toLowerCase());
  }
}

class TransactionItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String category;

  TransactionItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}
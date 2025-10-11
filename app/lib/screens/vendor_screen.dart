import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../models/menu_item.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/notification_service.dart';
import '../utils/navigation_utils.dart';
import '../widgets/custom_app_bar.dart';

class VendorScreen extends StatefulWidget {
  @override
  _VendorScreenState createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  List<MenuItem> menuItems = [];
  List<MenuItem> cartItems = [];
  double totalAmount = 0.0;
  bool waitingForRFID = false;

  // For animations
  late AnimationController _animationController;
  late Animation<double> _animation;

  // For filtering menu items
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  // For shimmer loading effect
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.repeat(reverse: true);
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final items = await _authService.getMenuItems();

      // Extract unique categories
      final Set<String> categorySet = {'All'};
      for (var item in items) {
        categorySet.add(item.category);
      }

      setState(() {
        menuItems = items;
        _categories = categorySet.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startPollingRFID() {
    // Poll the API endpoint every 2 seconds when waiting for RFID
    Future.doWhile(() async {
      if (!waitingForRFID) return false;

      try {
        final response = await _authService.checkRFIDStatus();
        if (response != null) {
          // Show success animation instead of debug toast
          _showCardDetectedDialog(response);

          // Process transaction
          await _processRFIDTransaction(response);
          return false;
        }
      } catch (e) {
        print('Error polling RFID: $e');
        _showErrorSnackbar('Error scanning card', e.toString());
      }

      await Future.delayed(Duration(seconds: 7));
      return waitingForRFID;
    });
  }

  void _showCardDetectedDialog(String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(
        0.7,
      ), // Semi-transparent black overlay
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // GIF animation
                      Image.asset(
                        'assets/loading.gif', // Update with your actual GIF path
                        height: 120,
                        width: 120,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait while we process your transaction',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.red.shade800,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(message, style: TextStyle(fontSize: 14)),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.green.shade800,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItem = cartItems.firstWhere(
        (cartItem) => cartItem.id == item.id,
        orElse: () => item..quantity = 0,
      );

      if (!cartItems.contains(existingItem)) {
        existingItem.quantity = 1;
        cartItems.add(existingItem);
      } else {
        existingItem.quantity++;
      }

      _calculateTotal();
    });
  }

  void _removeFromCart(MenuItem item) {
    setState(() {
      item.quantity--;
      if (item.quantity <= 0) {
        cartItems.remove(item);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    totalAmount = cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> _processRFIDTransaction(String cardUID) async {
    try {
      if (totalAmount <= 0) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please add items to cart')));
        return;
      }

      // First get student data using cardUID
      final studentData = await _authService.getStudentByRFID(cardUID);

      if (studentData == null) {
        Navigator.of(context).pop(); // Close the dialog
        _showErrorSnackbar(
          'Student Not Found',
          'No student record found for this card.',
        );
        return;
      }

      final success = await _authService.processRFIDTransaction(
        cardUID,
        totalAmount,
      );

      if (success) {
        final currentUser = await _authService.getCurrentUser();
        final transaction = TransactionModel(
          id: '', // Firestore will generate this
          studentId: studentData['username'],
          vendorId: currentUser!.id,
          vendorName: currentUser.username,
          amount: totalAmount,
          timestamp: DateTime.now(),
          status: 'completed',
          type: 'purchase',
          items:
              cartItems
                  .map(
                    (item) => TransactionItem(
                      itemId: item.id,
                      name: item.name,
                      price: item.price,
                      quantity: item.quantity,
                      category: item.category,
                    ),
                  )
                  .toList(),
        );

        try {
          await _authService.saveTransaction(transaction);

          // Use the notification service
          await _notificationService.sendTransactionSMS(
            studentName: studentData['username'],
            amount: totalAmount,
            vendorName: currentUser.username,
            items: cartItems,
          );

          setState(() {
            cartItems.clear();
            totalAmount = 0;
            waitingForRFID = false;
          });

          Navigator.of(context).pop(); // Close the dialog
          _showTransactionSuccessDialog(studentData['username'], totalAmount);
        } catch (e) {
          Navigator.of(context).pop(); // Close the dialog
          _showErrorSnackbar('Transaction Error', e.toString());
          throw e;
        }
      } else {
        setState(() {
          waitingForRFID = false;
        });

        Navigator.of(context).pop(); // Close the dialog
        _showErrorSnackbar('Transaction Failed', 'Please try again');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close the dialog
      _showErrorSnackbar('Transaction Error', e.toString());
    }
  }

  void _showTransactionSuccessDialog(String studentName, double amount) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Transaction Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                SizedBox(height: 16),
                Text(
                  '$studentName was charged',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} tokens',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text('SMS notification sent to parent'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('CLOSE'),
              ),
            ],
          ),
    );
  }

  List<MenuItem> _getFilteredMenuItems() {
    return menuItems.where((item) {
      // Apply category filter
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    NavigationUtils.pushAndRemoveUntil(context, LoginScreen());
  }

  Widget _buildShimmerLoadingEffect() {
    return ListView.builder(
      itemCount: 8,
      padding: EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: 100,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 1200.ms,
              color: Theme.of(context).colorScheme.surfaceVariant,
            );
      },
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addToCart(item),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image or placeholder
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      brightness == Brightness.light
                          ? colors.primaryContainer
                          : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: colors.primary,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.price.toStringAsFixed(2)} tokens',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Text(item.category),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: _getCategoryColor(item.category),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: colors.onPrimary),
                  onPressed: () => _addToCart(item),
                  padding: EdgeInsets.zero,
                  iconSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: 50.ms * menuItems.indexOf(item),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'drink':
        return Icons.local_drink;
      case 'snack':
        return Icons.cookie;
      case 'dessert':
        return Icons.cake;
      case 'fruit':
        return Icons.apple;
      default:
        return Icons.fastfood;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange.shade700;
      case 'drink':
        return Colors.blue.shade700;
      case 'snack':
        return Colors.amber.shade700;
      case 'dessert':
        return Colors.pink.shade700;
      case 'fruit':
        return Colors.green.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  Widget _buildCartItem(MenuItem item) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          cartItems.remove(item);
          _calculateTotal();
        });
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Item thumbnail
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: colors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              // Item details
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(2)} tokens',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MaterialButton(
                      minWidth: 30,
                      height: 30,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: CircleBorder(),
                      onPressed: () => _removeFromCart(item),
                      child: Icon(Icons.remove, size: 18),
                    ),
                    Container(
                      width: 30,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    MaterialButton(
                      minWidth: 30,
                      height: 30,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: CircleBorder(),
                      onPressed: () => _addToCart(item),
                      child: Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(
      begin: 0.5,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildOrderSummary() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalAmount.toStringAsFixed(2)} tokens',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        if (cartItems.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add items from the menu',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  totalAmount > 0
                      ? () {
                        setState(() => waitingForRFID = true);
                        _startPollingRFID();
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    waitingForRFID ? Colors.orange : colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child:
                  waitingForRFID
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Waiting for card...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Process Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrLarger = screenWidth > 768;

    final filteredMenuItems = _getFilteredMenuItems();

    // Responsive layout
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Dashboard'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {}, // Replace with your transaction history function
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          isTabletOrLarger
              ? _buildWideLayout(filteredMenuItems)
              : _buildNarrowLayout(filteredMenuItems),
    );
  }

  Widget _buildWideLayout(List<MenuItem> filteredMenuItems) {
    return Row(
      children: [
        // Menu section (Left side)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSearchAndFilters(),
              Expanded(
                child:
                    _isLoading
                        ? _buildShimmerLoadingEffect()
                        : ListView.builder(
                          itemCount: filteredMenuItems.length,
                          padding: EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            return _buildMenuItem(filteredMenuItems[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
        // Cart section (Right side)
        Expanded(
          flex: 1,
          child: Card(
            margin: EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Current Order',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child:
                      cartItems.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: cartItems.length,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemBuilder: (context, index) {
                              return _buildCartItem(cartItems[index]);
                            },
                          ),
                ),
                _buildOrderSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(List<MenuItem> filteredMenuItems) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: TabBar(
              tabs: [
                Tab(text: 'Menu', icon: Icon(Icons.restaurant_menu)),
                Tab(
                  text: 'Cart',
                  icon: Badge(
                    label: Text('${cartItems.length}'),
                    isLabelVisible: cartItems.isNotEmpty,
                    child: Icon(Icons.shopping_cart),
                  ),
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Menu Tab
                Column(
                  children: [
                    _buildSearchAndFilters(),
                    Expanded(
                      child:
                          _isLoading
                              ? _buildShimmerLoadingEffect()
                              : ListView.builder(
                                itemCount: filteredMenuItems.length,
                                padding: EdgeInsets.all(8),
                                itemBuilder: (context, index) {
                                  return _buildMenuItem(
                                    filteredMenuItems[index],
                                  );
                                },
                              ),
                    ),
                  ],
                ),
                // Cart Tab
                Column(
                  children: [
                    Expanded(
                      child:
                          cartItems.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Your cart is empty',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add items from the menu tab',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: cartItems.length,
                                padding: EdgeInsets.all(8),
                                itemBuilder: (context, index) {
                                  return _buildCartItem(cartItems[index]);
                                },
                              ),
                    ),
                    _buildOrderSummary(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search box
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          SizedBox(height: 12),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    setState(() {
      waitingForRFID = false;
    });
    _animationController.dispose();
    super.dispose();
  }
}

// You'll need to extend the MenuItem class to include these properties
extension MenuItemExtension on MenuItem {
  // These would actually be in your MenuItem class
  String get description => 'Delicious ${name.toLowerCase()}'; // Placeholder
  String get category =>
      ['Food', 'Drink', 'Snack', 'Dessert'][name.length % 4]; // Placeholder
}

// Theme configuration - Add this to your main.dart
ThemeData lightTheme() {
  final ColorScheme colorScheme = ColorScheme.light(
    primary: Color(0xFF1565C0), // Deep blue
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD0E4FF),
    onPrimaryContainer: Color(0xFF0A3977),
    secondary: Color(0xFF00897B), // Teal
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFB2DFDB),
    onSecondaryContainer: Color(0xFF004D40),
    tertiary: Color(0xFFE57373), // Light red
    background: Colors.white,
    surface: Colors.white,
    surfaceVariant: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF424242),
    error: Colors.red.shade700,
  );

  return ThemeData.light().copyWith(
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData darkTheme() {
  final ColorScheme colorScheme = ColorScheme.dark(
    primary: Color(0xFF90CAF9), // Light blue
    onPrimary: Color(0xFF0D47A1), // Very dark blue
    primaryContainer: Color(0xFF1565C0),
    onPrimaryContainer: Color(0xFFD0E4FF),
    secondary: Color(0xFF80CBC4), // Light teal
    onSecondary: Color(0xFF00695C),
    secondaryContainer: Color(0xFF00796B),
    onSecondaryContainer: Color(0xFFB2DFDB),
    tertiary: Color(0xFFEF9A9A), // Light red
    background: Color(0xFF121212), // Dark background
    surface: Color(0xFF1E1E1E), // Dark surface
    surfaceVariant: Color(0xFF2D2D2D), // Slightly lighter surface
    onSurfaceVariant: Color(0xFFE0E0E0),
    error: Colors.red.shade300,
  );

  return ThemeData.dark().copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      fillColor: colorScheme.surfaceVariant,
      filled: true,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

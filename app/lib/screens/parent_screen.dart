import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../utils/navigation_utils.dart' show NavigationUtils;
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_animation.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_limit_screen.dart';
import '../services/ai_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentScreen extends StatefulWidget {
  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AIService _aiService = AIService();
  List<Map<String, dynamic>> _students = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  int _currentIndex = 0;  // Track current nav item
  String? _selectedStudent;
  String? _selectedCategory;
  double? _minAmount;
  double? _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStudentForAI;
  bool _isLoadingAI = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadStudents().then((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    if (currentUser != null) {
      final students = await _authService.getStudentsForParent(currentUser);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() => _isLoading = true);
      
      List<TransactionModel> allTransactions = [];
      
      for (var student in _students) {
        print('Debug: Loading transactions for ${student['username']}');
        final studentTransactions = 
            await _authService.getStudentTransactions(student['username']);
        allTransactions.addAll(studentTransactions);
      }

      print('Debug: Total transactions loaded: ${allTransactions.length}');

      var filtered = allTransactions;

      if (_selectedStudent != null && _selectedStudent!.isNotEmpty) {
        filtered = filtered.where((t) => t.studentId == _selectedStudent).toList();
        print('Debug: After student filter: ${filtered.length} transactions');
      }

      // Sort by timestamp
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      setState(() {
        _transactions = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
        _transactions = [];
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToWalletLimit(Map<String, dynamic> student) {
    NavigationUtils.pushScreen(
      context,
      WalletLimitScreen(students: [student]),
    );
  }



  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(student['username']),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'wallet_limit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletLimitScreen(
                        students: [student],
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'wallet_limit',
                  child: Row(
                    children: [
                      Icon(Icons.wallet),
                      SizedBox(width: 8),
                      Text('Update Wallet Limit'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${student['username']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('Class: ${student['class']}'),
                Text('Division: ${student['division']}'),
                Text('Roll Number: ${student['rollNo']}'),
                Text('Contact: ${student['contact']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionFilters() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  hint: Text('Select Student'),
                  value: _selectedStudent,
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Students'),
                    ),
                    ..._students.map((student) => DropdownMenuItem<String>(
                      value: student['username'],
                      child: Text(student['username']),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStudent = value;
                      print('Debug: Selected student: $value');
                    });
                    _loadTransactions();
                  },
                ),
                DropdownButton<String>(
                  hint: Text('Category'),
                  value: _selectedCategory,
                  items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      DropdownMenuItem<String>(value: 'healthy', child: Text('Healthy')),
                      DropdownMenuItem<String>(value: 'junk', child: Text('Junk')),
                      DropdownMenuItem<String>(value: 'mid', child: Text('Mid')),
                    ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      print('Debug: Selected category: $value');
                    });
                    _loadTransactions();
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.date_range),
                  label: Text(_startDate != null && _endDate != null 
                    ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                    : 'Date Range'
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                        ? DateTimeRange(start: _startDate!, end: _endDate!)
                        : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                        print('Debug: Selected date range: ${picked.start} - ${picked.end}');
                      });
                      _loadTransactions();
                    }
                  },
                ),
                if (_startDate != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadTransactions();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading) {
      return const Center(child: LoadingAnimation());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTransactionDetails(transaction),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${transaction.amount.toStringAsFixed(2)} tokens',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              _formatDate(transaction.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vendor: ${transaction.vendorName}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Items: ${transaction.items.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Transaction Details',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildDetailRow('Date', _formatDateTime(transaction.timestamp)),
                _buildDetailRow('Student', transaction.studentId),
                _buildDetailRow('Vendor', transaction.vendorName),
                _buildDetailRow('Amount', '${transaction.amount.toStringAsFixed(2)} tokens'),
                _buildDetailRow('Status', transaction.status),
                const SizedBox(height: 16),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...transaction.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('Category: ${item.category}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${item.price.toStringAsFixed(2)} tokens'),
                        Text('Qty: ${item.quantity}'),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAIAnalysisDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildAIAnalysisDialog(),
    );
  }

  Widget _buildAIAnalysisDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Text(
                'Select a student to analyze their transactions:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                hint: Text('Select Student'),
                value: _selectedStudentForAI,
                items: _students.map((student) {
                  return DropdownMenuItem<String>(
                    value: student['username'],
                    child: Text(student['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudentForAI = value;
                  });
                },
              ),
              SizedBox(height: 16),
              _buildAIOptionButton(
                icon: Icons.analytics,
                title: 'Spending Summary',
                onTap: () => _getAIAnalysis('spending_summary'),
              ),
              _buildAIOptionButton(
                icon: Icons.fastfood,
                title: 'Analyze Food Choices',
                onTap: () => _getAIAnalysis('food_choices'),
              ),
              _buildAIOptionButton(
                icon: Icons.trending_up,
                title: 'Analyze Spending Trends',
                onTap: () => _getAIAnalysis('spending_trends'),
              ),
              _buildAIOptionButton(
                icon: Icons.health_and_safety,
                title: 'Health Analysis',
                onTap: () => _getAIAnalysis('health_analysis'),
              ),
              if (_isLoadingAI)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing transactions...'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIOptionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getAIAnalysis(String analysisType) async {
    if (_selectedStudentForAI == null && _students.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a student first')),
      );
      return;
    }

    final studentId = _selectedStudentForAI ?? _students.first['username'];
    final studentTransactions = _transactions
        .where((t) => t.studentId == studentId)
        .map((t) => t.toMap())
        .toList();

    setState(() => _isLoadingAI = true);

    try {
      final analysis = await _aiService.analyzeTransactions(
        transactions: studentTransactions,
        analysisType: analysisType,
        studentName: studentId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Analysis Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(analysis ?? 'No analysis available'),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _currentIndex == 0 ? 'Parent Dashboard' : 'Transaction History',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () => _showAIAnalysisDialog(),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _currentIndex,
            children: [
              ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return _buildStudentCard(student);
                },
              ),
              Column(
                children: [
                  _buildTransactionFilters(),
                  Expanded(child: _buildTransactionList()),
                ],
              ),
            ],
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _loadTransactions();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showAIAnalysisDialog,
      //   child: Icon(Icons.psychology),
      //   tooltip: 'AI Analysis',
      // ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';

class WalletLimitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  
  WalletLimitScreen({required this.students});

  @override
  _WalletLimitScreenState createState() => _WalletLimitScreenState();
}

class _WalletLimitScreenState extends State<WalletLimitScreen> {
  final AuthService _authService = AuthService();
  final BlockchainService _blockchainService = BlockchainService();
  final Map<String, TextEditingController> _controllers = {};
  Map<String, double> _realTimeBalances = {};
  bool _isLoadingBalances = false;

  @override
  void initState() {
    super.initState();
    for (var student in widget.students) {
      String studentId = student['username'];
      _controllers[studentId] = TextEditingController(
        text: student['walletLimit']?.toString() ?? '0'
      );
    }
    _loadRealTimeBalances();
  }

  Future<void> _loadRealTimeBalances() async {
    setState(() {
      _isLoadingBalances = true;
    });

    try {
      for (var student in widget.students) {
        if (student['walletAddress'] != null) {
          print('Debug: Loading balance for ${student['username']} with wallet ${student['walletAddress']}');
          final balance = await _blockchainService.getWalletBalance(
            student['walletAddress']
          );
          print('Debug: Received balance $balance for ${student['username']}');
          setState(() {
            _realTimeBalances[student['username']] = balance;
          });
        } else {
          print('Debug: No wallet address for ${student['username']}');
        }
      }
    } catch (e) {
      print('Error loading balances: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load some balances: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isLoadingBalances = false;
      });
    }
  }

  Future<void> _refreshData() async {
    // Refresh students data from database
    final updatedStudents = await _authService.getAllStudents();
    setState(() {
      widget.students.clear();
      widget.students.addAll(updatedStudents);
    });
    // Refresh balances
    await _loadRealTimeBalances();
  }

  Future<void> _refreshStudentData(String username) async {
    try {
      final updatedStudent = await _authService.getStudentData(username);
      if (updatedStudent != null) {
        setState(() {
          final index = widget.students.indexWhere((s) => s['username'] == username);
          if (index != -1) {
            widget.students[index] = updatedStudent;
          }
        });
        // Refresh balance for this student
        if (updatedStudent['walletAddress'] != null) {
          final balance = await _blockchainService.getWalletBalance(
            updatedStudent['walletAddress']
          );
          setState(() {
            _realTimeBalances[username] = balance;
          });
        }
      }
    } catch (e) {
      print('Error refreshing student data: $e');
    }
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> student) async {
    // Get real-time balance first
    double currentBalance = 0;
    try {
      currentBalance = await _blockchainService.getWalletBalance(
        student['walletAddress']
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch current balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    final TextEditingController limitController = TextEditingController(
      text: student['walletLimit']?.toString() ?? '0'
    );
    final TextEditingController balanceController = TextEditingController(
      text: currentBalance.toString()
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => Center(
          child: Container(
            width: 400,
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
            child: Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Student: ${student['username']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'One Time Payment Limit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Payment Limit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: 'Tokens ',
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: balanceController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Current Balance',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixText: 'Tokens ',
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_circle),
                              onPressed: () {
                                currentBalance += 100;  // Increment by 100
                                balanceController.text = currentBalance.toString();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle),
                              onPressed: () {
                                if (currentBalance >= 100) {
                                  currentBalance -= 100;  // Decrement by 100
                                  balanceController.text = currentBalance.toString();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final BuildContext dialogContext = context;
                            final GlobalKey<State> loadingKey = GlobalKey<State>();
                            
                            try {
                              final newBalance = double.parse(balanceController.text);
                              final newLimit = double.parse(limitController.text);
                        
                              // Show loading overlay
                              showDialog(
                                context: dialogContext,
                                barrierDismissible: false,
                                builder: (BuildContext context) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: Center(
                                    key: loadingKey,
                                    child: Card(
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Processing transaction...'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              print(student['privateKey']);
                              print(student['walletAddress']);
                              print('Debug: Starting wallet update');
                              final success = await _blockchainService.updateWalletBalance(
                                student['walletAddress'],
                                student['privateKey'],
                                currentBalance,
                                newBalance,
                              );
                        
                              // Close loading overlay
                              if (loadingKey.currentContext != null) {
                                Navigator.of(loadingKey.currentContext!).pop();
                              }
                        
                              if (success) {
                                // Update limit if balance update was successful
                                final limitSuccess = await _authService.updateWalletLimit(
                                  student['username'],
                                  newLimit,
                                );
                        
                                if (limitSuccess) {
                                  // Update was successful, close dialog
                                  Navigator.of(dialogContext).pop();
                                  
                                  // Refresh only this student's data
                                  await _refreshStudentData(student['username']);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Wallet updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update wallet limit'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update wallet balance'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Error in wallet update: $e');
                              
                              // Close loading overlay if still showing
                              if (loadingKey.currentContext != null) {
                                Navigator.of(loadingKey.currentContext!).pop();
                              }
                        
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Wallet Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoadingBalances ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoadingBalances 
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final student = widget.students[index];
              final realTimeBalance = _realTimeBalances[student['username']] ?? 0.0;

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    'Student: ${student['username']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        'Wallet Address: ${student['walletAddress']}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Current Balance: $realTimeBalance tokens',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: realTimeBalance > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (_isLoadingBalances)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (!_isLoadingBalances)
                            IconButton(
                              icon: Icon(Icons.refresh, size: 20),
                              onPressed: () => _loadRealTimeBalances(),
                              tooltip: 'Refresh Balance',
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Payment Limit: ${student['walletLimit'] ?? 0} tokens',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showUpdateDialog(student),
                    child: Text('Update Wallet\nSettings', textAlign: TextAlign.center),
                  ),
                ),
              );
            },
          ),
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}

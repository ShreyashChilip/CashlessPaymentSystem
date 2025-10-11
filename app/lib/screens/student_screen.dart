import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/navigation_utils.dart';
import 'login_screen.dart';

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    NavigationUtils.pushAndRemoveUntil(context, LoginScreen());
  }

  void _showWalletDetails() {
    // Implement wallet details display
  }

  // void _navigateToTransactionHistory() {
  //   NavigationUtils.pushScreen(
  //     context,
  //     TransactionHistoryScreen(studentId: currentUser?.id ?? ''),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.exit_to_app),
          //   onPressed: () => _logout(context),
          // ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _showWalletDetails(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Welcome to Student Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'You are logged in as a student',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.assignment),
                        title: Text('Assignments'),
                        subtitle: Text('View your pending assignments'),
                        onTap: () {
                          // Navigate to assignments
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.grading),
                        title: Text('Grades'),
                        subtitle: Text('Check your recent grades'),
                        onTap: () {
                          // Navigate to grades
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('Schedule'),
                        subtitle: Text('View your class schedule'),
                        onTap: () {
                          // Navigate to schedule
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
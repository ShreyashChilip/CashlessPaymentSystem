import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/vendor_screen.dart';
import '../services/auth_service.dart';
import '../utils/navigation_utils.dart';
import 'package:animate_do/animate_do.dart'; // Add this package
import 'register_screen.dart';
import 'student_screen.dart';
import 'parent_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    _checkCurrentUser();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkCurrentUser() async {
    setState(() => _isLoading = true);
    
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser != null) {
      _navigateBasedOnRole(currentUser.role);
    }
    
    setState(() => _isLoading = false);
  }
  
  void _navigateBasedOnRole(String role) {
    if (role == 'student') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentScreen())
      );
    } else if (role == 'parent') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ParentScreen())
      );
    }
    else if (role == 'vendor') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VendorScreen())
      );
    }
  }

  void _onLoginSuccess(String role) {
    switch (role) {
      case 'student':
        NavigationUtils.pushAndRemoveUntil(context, StudentScreen());
        break;
      case 'parent':
        NavigationUtils.pushAndRemoveUntil(context, ParentScreen());
        break;
      case 'vendor':
        NavigationUtils.pushAndRemoveUntil(context, VendorScreen());
        break;
    }
  }
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      try {
        final user = await _authService.login(_username, _password);
        
        if (user != null) {
          _navigateBasedOnRole(user.role);
        } else {
          setState(() {
            _errorMessage = 'Invalid username or password';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.tealAccent : Colors.teal;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final surfaceColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Container(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Hero(
                            tag: 'logo',
                            child: FadeInDown(
                              duration: Duration(milliseconds: 1000),
                              child: Center(
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 60,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 200),
                                  child: Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 8),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 300),
                                  child: Text(
                                    'Sign in to continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 32),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 400),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_outline),
                                      filled: true,
                                      fillColor: surfaceColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                    ),
                                    style: TextStyle(color: textColor),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) => _username = value!,
                                  ),
                                ),
                                SizedBox(height: 16),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 500),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible 
                                            ? Icons.visibility 
                                            : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: surfaceColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                    ),
                                    obscureText: !_isPasswordVisible,
                                    style: TextStyle(color: textColor),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) => _password = value!,
                                  ),
                                ),
                                SizedBox(height: 8),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 600),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value!;
                                                });
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                if (_errorMessage.isNotEmpty)
                                  FadeInUp(
                                    duration: Duration(milliseconds: 1000),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage,
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (_errorMessage.isNotEmpty) SizedBox(height: 16),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 700),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 800),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 1,
                                        width: 80,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        width: 80,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                FadeInUp(
                                  duration: Duration(milliseconds: 1000),
                                  delay: Duration(milliseconds: 900),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _socialLoginButton(
                                        icon: Icons.g_mobiledata,
                                        color: isDarkMode ? Colors.white : Colors.red,
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          try {
                                            final userCredential = await _googleAuthService.signInWithGoogle();
                                            if (userCredential != null) {
                                              // You might need to adapt this based on your user role logic
                                              _onLoginSuccess('student'); // or determine role from userCredential
                                            }
                                          } catch (e) {
                                            setState(() {
                                              _errorMessage = 'Google sign in failed. Please try again.';
                                            });
                                          }
                                          setState(() => _isLoading = false);
                                        },
                                      ),
                                      SizedBox(width: 16),
                                      _socialLoginButton(
                                        icon: Icons.facebook,
                                        color: Colors.blue,
                                        onPressed: () {},
                                      ),
                                      SizedBox(width: 16),
                                      _socialLoginButton(
                                        icon: Icons.apple,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1000),
                            delay: Duration(milliseconds: 1000),
                            child: Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => RegisterScreen())
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                    children: [
                                      TextSpan(text: "Don't have an account? "),
                                      TextSpan(
                                        text: 'Register',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
  
  Widget _socialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2E2E2E) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
      ),
    );
  }
}
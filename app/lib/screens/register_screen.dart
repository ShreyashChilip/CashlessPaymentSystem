import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/vendor_screen.dart';
import '../services/auth_service.dart';
import 'student_screen.dart';
import 'parent_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  String _username = '';
  String _password = '';
  String _confirmPassword = '';
  String _role = 'student';
  bool _isLoading = false;
  String _errorMessage = '';
  
  // New fields for student
  String _contact = '';
  String _class = '';
  String _division = '';
  String _rollNo = '';
  String _walletAddress = '';
  String _rfidUID = ''; // New field for RFID card UID
  String _privateKey = ''; // New field for wallet private key
  
  // New fields for parent
  List<String> _studentIds = [];
  
  // Controller for student ID input
  final TextEditingController _studentIdController = TextEditingController();

  // New fields for vendor
  String _vendorName = '';
  String _vendorCategory = '';
  String _vendorWalletAddress = '';

  // Add new name fields
  String _fullName = '';
  String _parentName = '';
  String _vendorOwnerName = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_password != _confirmPassword) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }

      // Validate username
      if (_username.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Username cannot be empty';
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      try {
        Map<String, dynamic> additionalData = {};
        
        if (_role == 'student') {
          additionalData = {
            'fullName': _fullName,
            'contact': _contact,
            'class': _class,
            'division': _division,
            'rollNo': _rollNo,
            'walletAddress': _walletAddress.trim(),
            'walletLimit': 100.0,
            'rfidUID': _rfidUID.trim(),
            'privateKey': _privateKey.trim(),
          };
        } else if (_role == 'vendor') {
          additionalData = {
            'vendorName': _vendorName.trim(),
            'ownerName': _vendorOwnerName.trim(),
            'category': _vendorCategory.trim(),
            'walletAddress': _vendorWalletAddress.trim(),
          };
        } else {
          // Validate student IDs for parent
          if (_studentIds.isEmpty) {
            setState(() {
              _errorMessage = 'Please add at least one student';
              _isLoading = false;
            });
            return;
          }
          additionalData = {
            'parentName': _parentName.trim(),
            'studentIds': _studentIds,
          };
        }
        
        final user = await _authService.register(
          _username.trim(),
          _password,
          _role,
          additionalData
        );
        
        if (user != null) {
          // Navigate based on role
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _role == 'student' 
                ? StudentScreen()
                : _role == 'vendor'
                  ? VendorScreen()
                  : ParentScreen()
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Username already exists or registration failed';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Registration failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            hintText: 'Enter your full name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
          onSaved: (value) => _fullName = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Wallet Address',
            border: OutlineInputBorder(),
            hintText: 'Wallet address',
            helperText: 'Enter your wallet address',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter wallet address';
            }
            return null;
          },
          onSaved: (value) => _walletAddress = value!.toLowerCase(), // Convert to lowercase for consistency
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Contact Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact number';
            }
            return null;
          },
          onSaved: (value) => _contact = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Class',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter class';
            }
            return null;
          },
          onSaved: (value) => _class = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Division',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter division';
            }
            return null;
          },
          onSaved: (value) => _division = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Roll Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter roll number';
            }
            return null;
          },
          onSaved: (value) => _rollNo = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'RFID UID',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter RFID UID';
            }
            return null;
          },
          onSaved: (value) => _rfidUID = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Wallet Private Key',
            border: OutlineInputBorder(),
            helperText: 'Enter your Solana wallet private key',
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Private key is required';
            }
            return null;
          },
          onSaved: (value) => _privateKey = value!,
        ),
      ],
    );
  }

  Widget _buildParentFields() {
    return Column(
      children: [
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Parent Name',
            border: OutlineInputBorder(),
            hintText: 'Enter parent\'s full name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter parent\'s name';
            }
            return null;
          },
          onSaved: (value) => _parentName = value!,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_studentIdController.text.isNotEmpty) {
                  setState(() {
                    _studentIds.add(_studentIdController.text);
                    _studentIdController.clear();
                  });
                }
              },
              child: Text('Add Student'),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_studentIds.isNotEmpty) ...[
          Text(
            'Added Students:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Column(
            children: _studentIds.map((studentId) => ListTile(
              title: Text(studentId),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle),
                onPressed: () {
                  setState(() {
                    _studentIds.remove(studentId);
                  });
                },
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildVendorFields() {
    return Column(
      children: [
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Owner Name',
            border: OutlineInputBorder(),
            hintText: 'Enter vendor owner\'s full name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter owner\'s name';
            }
            return null;
          },
          onSaved: (value) => _vendorOwnerName = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Vendor Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vendor name';
            }
            return null;
          },
          onSaved: (value) => _vendorName = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            hintText: 'e.g. Canteen, Stationary, etc.',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vendor category';
            }
            return null;
          },
          onSaved: (value) => _vendorCategory = value!,
        ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Wallet Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter wallet address';
            }
            return null;
          },
          onSaved: (value) => _vendorWalletAddress = value!,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                    onSaved: (value) => _username = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                    onSaved: (value) => _confirmPassword = value!,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    value: _role,
                    items: [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('Parent'),
                      ),
                      DropdownMenuItem(
                        value: 'vendor',
                        child: Text('Vendor'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _role = value!;
                      });
                    },
                  ),
                  
                  // Conditional fields based on role
                  if (_role == 'student')
                    _buildStudentFields()
                  else if (_role == 'vendor')
                    _buildVendorFields()
                  else
                    _buildParentFields(),
                    
                  SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _register,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
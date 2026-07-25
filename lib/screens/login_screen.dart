import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rides_provider.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _step = 'phone'; // 'phone' | 'otp' | 'register'
  String _authMode = 'login'; // 'login' | 'register'

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _gender = 'Male';
  String _photo = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

  String _verificationId = '';
  bool _loading = false;
  String _errorMsg = '';
  User? _existingUser;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final cleanPhone = _phoneController.text.trim();
    if (cleanPhone.length != 10) {
      setState(() => _errorMsg = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final user = await FirebaseService.getUserFromFirestore(cleanPhone);
    _existingUser = user;

    if (_authMode == 'register' && user != null) {
      setState(() {
        _errorMsg = 'Account already exists for +91 $cleanPhone. Please Sign In instead.';
        _authMode = 'login';
        _loading = false;
      });
      return;
    }

    if (_authMode == 'login' && user == null) {
      setState(() {
        _errorMsg = 'No account found for +91 $cleanPhone. Please click "Register New User" to sign up.';
        _authMode = 'register';
        _loading = false;
      });
      return;
    }

    await FirebaseService.sendPhoneOtp(
      phoneNumber: cleanPhone,
      onCodeSent: (verId) {
        setState(() {
          _verificationId = verId;
          _step = 'otp';
          _loading = false;
        });
      },
      onError: (errMsg) {
        setState(() {
          _errorMsg = errMsg;
          _loading = false;
        });
      },
    );
  }

  void _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMsg = 'Please enter the 6-digit OTP code sent via SMS');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    try {
      await FirebaseService.verifyOtp(
        verificationId: _verificationId,
        smsCode: code,
      );

      if (_existingUser != null) {
        context.read<RidesProvider>().login(_existingUser!);
      } else {
        setState(() {
          _step = 'register';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Invalid OTP code. Please check your SMS and try again.';
        _loading = false;
      });
    }
  }

  void _handleRegister() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your full name');
      return;
    }
    if (!_emailController.text.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final newUser = User(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      gender: _gender,
      photo: _photo,
    );

    await context.read<RidesProvider>().login(newUser);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_car, size: 48, color: primary),
                ),
                const SizedBox(height: 12),
                Text('AutoShare', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
                Text('Secure Phone OTP Login & Ride Pooling', style: TextStyle(color: textSecondary, fontSize: 14)),
                const SizedBox(height: 24),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMsg.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),

                      // Step 1: Phone
                      if (_step == 'phone') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Sign In')),
                                selected: _authMode == 'login',
                                selectedColor: primary,
                                onSelected: (sel) => setState(() => _authMode = 'login'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Register New')),
                                selected: _authMode == 'register',
                                selectedColor: primary,
                                onSelected: (sel) => setState(() => _authMode = 'register'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            prefixText: '+91 ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loading ? null : _handleSendOtp,
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_authMode == 'register' ? 'Send OTP & Register' : 'Send OTP & Sign In'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('OR', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final phone = _phoneController.text.trim().isNotEmpty
                                  ? _phoneController.text.trim()
                                  : '9912345678';
                              final demoUser = User(
                                name: _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : 'Test Rider',
                                phone: phone,
                                email: 'testrider_$phone@autoshare.com',
                                gender: 'Male',
                                photo: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                              );
                              context.read<RidesProvider>().login(demoUser);
                            },
                            icon: Icon(Icons.flash_on, color: primary),
                            label: Text(
                              'Quick Test Login (Bypass SMS)',
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],

                      // Step 2: OTP
                      if (_step == 'otp') ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => setState(() => _step = 'phone'),
                            ),
                            Text('Verify OTP Code', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        Text('Sent via SMS to +91 ${_phoneController.text}', style: TextStyle(color: textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Enter 6-Digit OTP',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            ),
                            onPressed: _loading ? null : _handleVerifyOtp,
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Verify & Continue'),
                          ),
                        ),
                      ],

                      // Step 3: Register
                      if (_step == 'register') ...[
                        Text('Complete Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primary),
                            onPressed: _loading ? null : _handleRegister,
                            child: const Text('Complete Registration'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

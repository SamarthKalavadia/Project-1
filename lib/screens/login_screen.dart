import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/rides_provider.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'login'; // 'login' | 'register'
  String _step = 'input'; // 'input' | 'otp'

  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  String _gender = 'Male';
  String _photo = '';

  bool _loading = false;
  String _errorMsg = '';
  String _generatedOtp = '123456';
  User? _fetchedUser;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController(text: '123456');
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photo = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _handleInitiateLogin() async {
    final cleanPhone = _phoneController.text.trim();
    if (cleanPhone.length != 10) {
      setState(() => _errorMsg = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final existingUser = await FirebaseService.getUserFromFirestore(cleanPhone);
    _fetchedUser = existingUser;

    if (existingUser == null) {
      setState(() {
        _loading = false;
        _errorMsg = 'Account not registered for +91 $cleanPhone. Please switch to "Register" tab to create your profile.';
      });
      return;
    }

    setState(() {
      _loading = false;
      _generatedOtp = '123456';
      _otpController.text = '123456';
      _step = 'otp';
    });
  }

  void _handleInitiateRegister() async {
    final name = _nameController.text.trim();
    final cleanPhone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMsg = 'Please enter your full name');
      return;
    }
    if (cleanPhone.length != 10) {
      setState(() => _errorMsg = 'Please enter a valid 10-digit mobile number');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final existingUser = await FirebaseService.getUserFromFirestore(cleanPhone);

    if (existingUser != null) {
      setState(() {
        _loading = false;
        _errorMsg = 'Account already registered for +91 $cleanPhone! Please switch to "Sign In" tab to log in.';
      });
      return;
    }

    setState(() {
      _loading = false;
      _generatedOtp = '123456';
      _otpController.text = '123456';
      _step = 'otp';
    });
  }

  void _handleVerifyOtpAndLogin() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp != _generatedOtp && enteredOtp != '123456' && enteredOtp != '000000') {
      setState(() => _errorMsg = 'Invalid OTP code! Please enter $_generatedOtp');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    final cleanPhone = _phoneController.text.trim();

    if (_mode == 'login') {
      final userToLogin = _fetchedUser ??
          User(
            name: 'User $cleanPhone',
            photo: _photo.isNotEmpty ? _photo : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
            phone: cleanPhone,
            email: 'user_$cleanPhone@autoshare.com',
            gender: _gender,
          );
      context.read<RidesProvider>().login(userToLogin);
    } else {
      final newUser = User(
        name: _nameController.text.trim(),
        photo: _photo.isNotEmpty ? _photo : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        phone: cleanPhone,
        email: _emailController.text.trim().toLowerCase(),
        gender: _gender,
      );

      await FirebaseService.saveUserToFirestore(newUser);
      if (mounted) {
        context.read<RidesProvider>().login(newUser);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Logo
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
                  const SizedBox(height: 4),
                  Text('Real-time Carpooling & Ride Sharing', style: TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(height: 24),

                  // Mode Segment Control (Sign In vs Register)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _mode = 'login';
                              _step = 'input';
                              _errorMsg = '';
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _mode == 'login' ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: _mode == 'login' ? Colors.white : textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _mode = 'register';
                              _step = 'input';
                              _errorMsg = '';
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _mode == 'register' ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Register New User',
                                  style: TextStyle(
                                    color: _mode == 'register' ? Colors.white : textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Banner
                        if (_errorMsg.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMsg,
                                    style: const TextStyle(color: Colors.red, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // STEP 1: INPUT
                        if (_step == 'input') ...[
                          if (_mode == 'login') ...[
                            Text('Sign In to Your Account', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Enter your registered 10-digit mobile number', style: TextStyle(color: textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              maxLength: 10,
                              enabled: true,
                              readOnly: false,
                              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                counterText: '',
                                labelText: 'Mobile Phone Number',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixText: '+91 ',
                                prefixStyle: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                prefixIcon: Icon(Icons.phone, color: primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _loading ? null : _handleInitiateLogin,
                                child: _loading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Send Verification OTP',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                              ),
                            ),
                          ] else ...[
                            Text('Create New Account', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Fill details below to register', style: TextStyle(color: textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),

                            // Profile Picture Upload Selector
                            Center(
                              child: Column(
                                children: [
                                  UserAvatar(
                                    photoUrl: _photo,
                                    name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
                                    radius: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary.withOpacity(0.12),
                                          foregroundColor: primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _pickImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library, size: 16),
                                        label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary.withOpacity(0.12),
                                          foregroundColor: primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _pickImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt, size: 16),
                                        label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: _nameController,
                              enabled: true,
                              readOnly: false,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                labelText: 'Full Name *',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixIcon: Icon(Icons.person, color: primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              maxLength: 10,
                              enabled: true,
                              readOnly: false,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                counterText: '',
                                labelText: 'Mobile Phone Number *',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixText: '+91 ',
                                prefixStyle: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                                prefixIcon: Icon(Icons.phone, color: primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: true,
                              readOnly: false,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                labelText: 'Email Address *',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixIcon: Icon(Icons.email, color: primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primary, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: ['Male', 'Female', 'Other'].map((g) {
                                final isSel = _gender == g;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Center(
                                        child: Text(
                                          g,
                                          style: TextStyle(
                                            color: isSel ? Colors.white : textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      selected: isSel,
                                      selectedColor: primary,
                                      backgroundColor: inputBg,
                                      onSelected: (sel) => setState(() => _gender = g),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _loading ? null : _handleInitiateRegister,
                                child: _loading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Send Registration OTP',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ],

                        // STEP 2: OTP VERIFICATION
                        if (_step == 'otp') ...[
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() {
                                  _step = 'input';
                                  _errorMsg = '';
                                }),
                              ),
                              Text('Verify OTP Code', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Prominent Demo OTP Alert Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_clock, color: primary, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Verification OTP Code',
                                      style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your Demo OTP is:',
                                      style: TextStyle(color: textSecondary, fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _generatedOtp,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputBg,
                              counterText: '',
                              labelText: 'Enter 6-Digit OTP Code',
                              labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _loading ? null : _handleVerifyOtpAndLogin,
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      _mode == 'register' ? 'Verify & Create Account' : 'Verify & Sign In',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
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
      ),
    );
  }
}

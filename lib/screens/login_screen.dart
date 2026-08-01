import 'dart:async';
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
  String _step = 'input'; // 'input' | 'verify_email'

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;

  bool _obscurePassword = true;
  String _gender = 'Male';
  String _photo = '';

  bool _loading = false;
  String _errorMsg = '';
  User? _pendingUser;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController(text: '123456'); // Default password for simple UX
    _phoneController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final isVerified = await FirebaseService.isEmailVerified();
      if (isVerified) {
        timer.cancel();
        _completeLogin();
      }
    });
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    try {
      // Check if user exists in Firestore
      var existingUser = await FirebaseService.getUserByEmailFromFirestore(email);
      if (existingUser == null && _phoneController.text.isNotEmpty) {
        existingUser = await FirebaseService.getUserFromFirestore(_phoneController.text.trim());
      }

      final cleanPhone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : (existingUser?.phone.isNotEmpty == true ? existingUser!.phone : '9999999999');

      _pendingUser = existingUser ??
          User(
            name: email.split('@').first,
            photo: _photo,
            phone: cleanPhone,
            email: email.toLowerCase(),
            gender: _gender,
          );

      // Send Firebase Email Verification Link
      final alreadyVerified = await FirebaseService.sendFirebaseEmailVerification(
        email: email,
        password: password,
      );

      if (alreadyVerified) {
        _completeLogin();
        return;
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _step = 'verify_email';
        });
        _startVerificationTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification link sent to $email via Firebase Email!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = cleanErr;
        });
      }
    }
  }

  void _handleInitiateRegister() async {
    final name = _nameController.text.trim();
    final cleanPhone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

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
    if (password.isEmpty || password.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    // Check 1: Check if Phone already exists in Firestore
    final existingPhoneUser = await FirebaseService.getUserFromFirestore(cleanPhone);
    if (existingPhoneUser != null) {
      setState(() {
        _loading = false;
        _errorMsg = 'User already exists with Mobile Number +91 $cleanPhone! Please switch to "Sign In" tab to log in.';
      });
      return;
    }

    // Check 2: Check if Email already exists in Firestore
    final existingEmailUser = await FirebaseService.getUserByEmailFromFirestore(email);
    if (existingEmailUser != null) {
      setState(() {
        _loading = false;
        _errorMsg = 'User already exists with Email address "$email"! Please switch to "Sign In" tab to log in.';
      });
      return;
    }

    _pendingUser = User(
      name: name,
      photo: _photo,
      phone: cleanPhone,
      email: email.toLowerCase(),
      gender: _gender,
    );

    try {
      final alreadyVerified = await FirebaseService.sendFirebaseEmailVerification(
        email: email,
        password: password,
      );
      if (alreadyVerified) {
        _completeLogin();
        return;
      }
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = cleanErr;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _step = 'verify_email';
      });
      _startVerificationTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent to $email via Firebase Auth!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _checkEmailVerificationManual() async {
    setState(() => _loading = true);
    final isVerified = await FirebaseService.isEmailVerified();
    setState(() => _loading = false);

    if (isVerified) {
      _completeLogin();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet! Please click the link sent to your email inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _resendEmail() async {
    try {
      await FirebaseService.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resend error: $e')),
        );
      }
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Please enter your registered email address');
      return;
    }

    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    try {
      await FirebaseService.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _loading = false;
          _step = 'input';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email! Please check your Gmail inbox.'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = cleanErr;
        });
      }
    }
  }

  void _completeLogin() async {
    _verificationTimer?.cancel();
    final userToLogin = _pendingUser ??
        User(
          name: _nameController.text.isNotEmpty ? _nameController.text.trim() : 'Verified User',
          photo: _photo,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '9999999999',
          email: _emailController.text.trim().toLowerCase(),
          gender: _gender,
        );

    await FirebaseService.saveUserToFirestore(userToLogin);
    if (mounted) {
      context.read<RidesProvider>().login(userToLogin);
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

                  if (_step == 'input') ...[
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
                  ],

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

                        // STEP 1: FORM INPUT
                        if (_step == 'input') ...[
                          if (_mode == 'login') ...[
                            Text('Sign In with Email', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Enter your email address & password to sign in', style: TextStyle(color: textSecondary, fontSize: 13)),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                labelText: 'Email Address',
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
                            const SizedBox(height: 12),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                labelText: 'Password',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixIcon: Icon(Icons.lock, color: primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textSecondary),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _step = 'forgot_password';
                                  _errorMsg = '';
                                }),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

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
                                        'Sign In & Verify Email',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                              ),
                            ),
                          ] else ...[
                            Text('Create New Account', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Fill details below to register & verify email', style: TextStyle(color: textSecondary, fontSize: 13)),
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
                            const SizedBox(height: 12),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: inputBg,
                                labelText: 'Password *',
                                labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                                prefixIcon: Icon(Icons.lock, color: primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textSecondary),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
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
                                        'Create Account & Verify Email',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ],

                        // STEP 2: FIREBASE EMAIL VERIFICATION PENDING SCREEN
                        if (_step == 'verify_email') ...[
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mark_email_unread_outlined, size: 52, color: Colors.amber),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Verify Your Email Address',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'A Firebase verification link has been sent to:',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _emailController.text.trim(),
                                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 15),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: border),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Auto-checking verification status...',
                                            style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Please open your email inbox, click the verification link, then tap the button below or wait a moment to be redirected automatically.',
                                        style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _loading ? null : _checkEmailVerificationManual,
                                    icon: _loading
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.verified_user),
                                    label: const Text(
                                      'I Have Verified My Email',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _resendEmail,
                                        icon: const Icon(Icons.send_outlined, size: 16),
                                        label: const Text('Resend Email', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () {
                                          _verificationTimer?.cancel();
                                          setState(() {
                                            _step = 'input';
                                            _errorMsg = '';
                                          });
                                        },
                                        icon: const Icon(Icons.edit_note, size: 16),
                                        label: const Text('Change Details', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // STEP 3: FORGOT PASSWORD VIEW
                        if (_step == 'forgot_password') ...[
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() {
                                  _step = 'input';
                                  _errorMsg = '';
                                }),
                              ),
                              Text('Forgot Password', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your registered email address below. We will send a password reset link directly to your Gmail inbox.',
                            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputBg,
                              labelText: 'Registered Email Address',
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
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _loading ? null : _handleForgotPassword,
                              icon: _loading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.mark_email_read),
                              label: const Text(
                                'Send Password Reset Link',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

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
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
    _nameController = TextEditingController();

    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
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
    _verificationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
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

      // Check if email is already verified or needs verification
      final alreadyVerified = await FirebaseService.sendFirebaseEmailVerification(
        email: email,
        password: password,
      );

      if (alreadyVerified) {
        // Email is ALREADY verified -> Directly navigate to Home screen
        _completeLogin();
        return;
      }

      // Email is NOT verified -> Show "Verify Email" screen & start 2s auto-checking timer
      if (mounted) {
        setState(() {
          _loading = false;
          _step = 'verify_email';
        });
        _startVerificationTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification link sent to $email! Please verify your email to continue.'),
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

  void _handleGoogleSignIn() async {
    setState(() {
      _errorMsg = '';
      _loading = true;
    });

    try {
      final user = await FirebaseService.signInWithGoogle();
      if (user != null) {
        if (mounted) {
          context.read<RidesProvider>().login(user);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Google Sign-In: $cleanErr';
        });
      }
    }
  }

  Widget _buildPasswordStrengthIndicator(String password, BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    String text;
    double progress;
    String tip;

    if (password.length < 6) {
      color = Colors.red;
      text = 'Weak';
      progress = 0.33;
      tip = 'Password must be at least 6 characters.';
    } else {
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasDigits = password.contains(RegExp(r'[0-9]'));
      bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if (password.length >= 8 && hasUppercase && (hasDigits || hasSpecial)) {
        color = Colors.green;
        text = 'Strong';
        progress = 1.0;
        tip = 'Great! Your password is secure.';
      } else if (hasDigits || hasUppercase || hasSpecial) {
        color = Colors.orange;
        text = 'Medium';
        progress = 0.66;
        tip = 'Include uppercase letters, numbers & special symbols.';
      } else {
        color = Colors.red;
        text = 'Weak';
        progress = 0.33;
        tip = 'Must include numbers or uppercase letters.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password Strength:', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            color: color,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tip,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton({required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: border, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Divider(color: border, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: cardBg,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _handleGoogleSignIn,
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            label: Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
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
                                _passwordController.clear();
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
                                _passwordController.clear();
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
                            _buildGoogleSignInButton(label: 'Sign In with Google'),
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
                            _buildGoogleSignInButton(label: 'Register with Google'),
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
                                        'Please open your email inbox and click the verification link. You will be automatically redirected to the Home screen as soon as your email is verified.',
                                        style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

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
                          _buildPasswordStrengthIndicator(_passwordController.text, context),
                          const SizedBox(height: 14),

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

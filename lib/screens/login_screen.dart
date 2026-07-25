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
  String _activeTab = 'preset'; // 'preset' | 'custom'
  String _step = 'phone'; // 'phone' | 'otp' | 'register'

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

  final List<User> _presetUsers = [
    User(
      name: "Test Rider",
      photo: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
      phone: "9912345678",
      email: "testrider_9912345678@autoshare.com",
      gender: "Male",
    ),
    User(
      name: "Rohan Das",
      photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
      phone: "9734567890",
      email: "rohan.das@gmail.com",
      gender: "Male",
    ),
    User(
      name: "Sneha Reddy",
      photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
      phone: "9645678901",
      email: "sneha.r@university.edu",
      gender: "Female",
    ),
    User(
      name: "Priya Patel",
      photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
      phone: "9812345678",
      email: "priya.p@company.com",
      gender: "Female",
    ),
  ];

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

  void _handleCustomRegister() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your full name');
      return;
    }
    if (_phoneController.text.trim().length != 10) {
      setState(() => _errorMsg = 'Please enter a valid 10-digit phone number');
      return;
    }

    final newUser = User(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim().toLowerCase()
          : '${_nameController.text.trim().toLowerCase().replaceAll(" ", "")}@autoshare.com',
      gender: _gender,
      photo: _photo,
    );

    context.read<RidesProvider>().login(newUser);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
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

                // Mode Segment Selector
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
                            _activeTab = 'preset';
                            _errorMsg = '';
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 'preset' ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Quick Demo Login',
                                style: TextStyle(
                                  color: _activeTab == 'preset' ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _activeTab = 'custom';
                            _errorMsg = '';
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 'custom' ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'SMS OTP / Register',
                                style: TextStyle(
                                  color: _activeTab == 'custom' ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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

                // Main Content Card
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

                      if (_activeTab == 'preset') ...[
                        Text(
                          'Select a test user to log in instantly:',
                          style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ..._presetUsers.map((user) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.photo),
                              ),
                              title: Text(user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text('${user.gender} • +91 ${user.phone}', style: TextStyle(color: textSecondary, fontSize: 12)),
                              trailing: Icon(Icons.chevron_right, color: primary),
                              onTap: () => context.read<RidesProvider>().login(user),
                            ),
                          );
                        }),
                      ] else ...[
                        if (_step == 'phone') ...[
                          Text('Enter phone details to verify:', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          Row(
                            children: ['Male', 'Female', 'Other'].map((g) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Center(child: Text(g, style: const TextStyle(fontSize: 12))),
                                    selected: _gender == g,
                                    selectedColor: primary,
                                    onSelected: (sel) => setState(() => _gender = g),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primary),
                              onPressed: _handleCustomRegister,
                              child: const Text('Register & Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : _handleSendOtp,
                              child: const Text('Send SMS OTP via Firebase'),
                            ),
                          ),
                        ],
                        if (_step == 'otp') ...[
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() => _step = 'phone'),
                              ),
                              Text('Verify OTP', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Text('Sent to +91 ${_phoneController.text}', style: TextStyle(color: textSecondary, fontSize: 13)),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: 'Enter 6-Digit OTP',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primary),
                              onPressed: _loading ? null : _handleVerifyOtp,
                              child: const Text('Verify OTP Code'),
                            ),
                          ),
                        ],
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

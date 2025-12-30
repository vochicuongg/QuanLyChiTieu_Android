import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback? onSkip;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onSkip,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    final result = await authService.signInWithGoogle();
    
    if (result != null) {
      widget.onLoginSuccess();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage == 'vi' 
                ? 'Đăng nhập thất bại. Vui lòng thử lại.'
                : 'Sign in failed. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4355F0), Color(0xFF2BC0E4), Color(0xFF4FF2C6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                const Text(
                  'VFinance',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appLanguage == 'vi'
                      ? 'Quản lý chi tiêu thông minh'
                      : 'Smart Expense Management',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                // Google Sign-In Button (fixed height to prevent layout shift)
                SizedBox(
                  height: 120, // Fixed height for button area
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _signInWithGoogle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.google.com/favicon.ico',
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.g_mobiledata, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      appLanguage == 'vi'
                                          ? 'Đăng nhập với Google'
                                          : 'Sign in with Google',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (widget.onSkip != null)
                              TextButton(
                                onPressed: widget.onSkip,
                                child: Text(
                                  appLanguage == 'vi' ? 'Bỏ qua' : 'Skip',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
                // Privacy note
                Text(
                  appLanguage == 'vi'
                      ? 'Đăng nhập để sao lưu dữ liệu của bạn'
                      : 'Sign in to backup your data',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

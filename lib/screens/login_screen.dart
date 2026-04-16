import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:rupix_admin_auth/services/auth_service.dart';
import 'package:rupix_admin_auth/utils/constants.dart';
import 'package:rupix_admin_auth/widgets/turnstile_widget.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onNavigateToForgotPassword;
  final VoidCallback? onNavigateToSignUp;
  final bool showSignUpLink;
  final bool showForgotPasswordLink;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onNavigateToForgotPassword,
    this.onNavigateToSignUp,
    this.showSignUpLink = false,
    this.showForgotPasswordLink = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  String? _captchaToken;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Set loading state to TRUE immediately
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_captchaToken == null) {
        setState(() {
          _errorMessage = "Please complete the security check first.";
          _isLoading = false;
        });
        return;
      }

      // 4. Turnstile succeeded - now perform the actual sign in
      debugPrint('Login: Proceeding with authentication');

      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        captchaToken: _captchaToken,
      );

      // 5. Handle successful login
      if (response.user != null && mounted) {
        debugPrint('Login: Authentication successful');
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      // 6. Handle any exceptions during the auth process
      debugPrint('Login: Error occurred - $e');
      if (mounted) {
        setState(() {
          // Clean up the error message for display
          String errorMsg = e.toString();
          if (errorMsg.contains('Invalid login credentials')) {
            errorMsg = 'Invalid email or password. Please try again.';
          } else if (errorMsg.contains('Email not confirmed')) {
            errorMsg = 'Please verify your email before logging in.';
          } else if (errorMsg.startsWith('Exception:')) {
            errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
          }
          _errorMessage = errorMsg;
        });
      }
    } finally {
      // 7. ALWAYS set loading state to FALSE in the 'finally' block
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildGlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Rupix Ecosystem',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Access by Rupix Labs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildTextField(
                          controller: _emailController,
                          labelText: 'EMAIL ADDRESS',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your email' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: _passwordController,
                          labelText: 'PASSWORD',
                          icon: Icons.lock_rounded,
                          obscureText: !_isPasswordVisible,
                          isPasswordField: true,
                          isPasswordVisible: _isPasswordVisible,
                          onVisibilityToggle: (visible) {
                            setState(() => _isPasswordVisible = visible);
                          },
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your password'
                              : null,
                        ),

                        if (widget.showForgotPasswordLink)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: widget.onNavigateToForgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Embedded Turnstile Widget
                        TurnstileWidget(
                          siteKey: AuthConstants.turnstileSiteKey,
                          onVerified: (token) {
                            setState(() {
                              _captchaToken = token;
                              _errorMessage = null;
                            });
                          },
                          onExpired: () {
                            setState(() => _captchaToken = null);
                          },
                          onError: (error) {
                            setState(() => _errorMessage = error);
                          },
                        ),

                        const SizedBox(height: 40),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'LOGIN NOW',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                        if (widget.showSignUpLink)
                          Column(
                            children: [
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "New to the ecosystem? ",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onNavigateToSignUp,
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPasswordField = false,
    bool isPasswordVisible = false,
    Function(bool)? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPasswordField
                ? GestureDetector(
                    onTapDown: (_) => onVisibilityToggle?.call(true),
                    onTapUp: (_) => onVisibilityToggle?.call(false),
                    onTapCancel: () => onVisibilityToggle?.call(false),
                    child: Icon(
                      isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

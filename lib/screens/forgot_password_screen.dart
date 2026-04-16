import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:rupix_admin_auth/services/auth_service.dart';
import 'package:rupix_admin_auth/utils/constants.dart';
import 'package:rupix_admin_auth/widgets/turnstile_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  String? _captchaToken;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      if (_captchaToken == null) {
        setState(() {
          _message = "Please complete the security check first.";
          _isSuccess = false;
          _isLoading = false;
        });
        return;
      }

      await _authService.signOut();
      await _authService.resetPasswordForEmail(
        _emailController.text.trim(),
        captchaToken: _captchaToken,
      );

      if (mounted) {
        setState(() {
          _message =
              'If an account exists, a reset link has been sent to your email.';
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'An error occurred. Please try again later.';
          _isSuccess = false;
        });
      }
    } finally {
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
      appBar: AppBar(
        title: const Text('Reset Access'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
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
                          Icons.lock_reset_rounded,
                          color: AppColors.primary,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Help is here',
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
                          'We\'ll send a magic link to your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 48),

                        if (_message != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _isSuccess
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isSuccess
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSuccess
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  color: _isSuccess ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _message!,
                                    style: TextStyle(
                                      color: _isSuccess
                                          ? Colors.green
                                          : Colors.red,
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

                        const SizedBox(height: 16),

                        // Embedded Turnstile Widget
                        TurnstileWidget(
                          siteKey: AuthConstants.turnstileSiteKey,
                          onVerified: (token) {
                            setState(() {
                              _captchaToken = token;
                              _message = null;
                            });
                          },
                          onExpired: () {
                            setState(() => _captchaToken = null);
                          },
                          onError: (error) {
                            setState(() {
                              _message = error;
                              _isSuccess = false;
                            });
                          },
                        ),

                        const SizedBox(height: 32),

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
                                  onPressed: _sendResetLink,
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
                                    'SEND RESET LINK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w900,
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
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:safe_vision/firebase_service/login_user.dart';
import 'package:safe_vision/pages/home_page.dart';
import 'package:safe_vision/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  
  late AnimationController _backgroundController;
  late AnimationController _formController;
  
  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Start form animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await LoginUser().loginUser(email: email, password: password);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Success"),
            content: Text("✅User Logged in Successfully"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("❌Failed to Login User"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9400D8).withOpacity(0.1),
              Color(0xFF9400D8).withOpacity(0.05),
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top Animation - signup.json
                  Container(
                    height: 280,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background glow effect
                        Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF9400D8).withOpacity(0.2),
                                Color(0xFF9400D8).withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: Offset(0.8, 0.8),
                            end: Offset(1.0, 1.0),
                            duration: 3.seconds,
                          )
                          .then()
                          .scale(
                            begin: Offset(1.0, 1.0),
                            end: Offset(0.8, 0.8),
                            duration: 3.seconds,
                          ),
                        
                        // Lottie Animation
                        Container(
                          height: 200,
                          width: 200,
                          child: Lottie.asset(
                            'animation_assets/signup.json',
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF9400D8).withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.security,
                                  size: 80,
                                  color: Color(0xFF9400D8),
                                ),
                              );
                            },
                          ),
                        ).animate()
                          .fadeIn(duration: 1.5.seconds)
                          .slideY(begin: -0.3, end: 0.0, duration: 1.2.seconds, curve: Curves.easeOutBack)
                          .then()
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .moveY(begin: 0, end: -5, duration: 2.seconds),
                      ],
                    ),
                  ),
                  
                 
                  
                  // App Title
                  Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9400D8),
                          height: 1.2,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideY(begin: 0.3, end: 0.0, duration: 600.ms),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to SafeVision',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0.0, duration: 600.ms),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Login Form with Background Animation
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF9400D8).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Background Animation
                          Positioned.fill(
                            child: Container(
                              child: Lottie.asset(
                                'animation_assets/background.json',
                                fit: BoxFit.cover,
                                repeat: true,
                                animate: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.9),
                                          Color(0xFF9400D8).withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Semi-transparent overlay
                          // Positioned.fill(
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       gradient: LinearGradient(
                          //         begin: Alignment.topCenter,
                          //         end: Alignment.bottomCenter,
                          //         colors: [
                          //           Colors.white.withOpacity(0.85),
                          //           Colors.white.withOpacity(0.95),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          
                          // Form Content
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Welcome Text
                                  Text(
                                    'Login to Continue',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9400D8),
                                    ),
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 700.ms)
                                    .slideX(begin: -0.3, end: 0.0, duration: 600.ms),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    'Enter your credentials to access your account',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 800.ms)
                                    .slideX(begin: -0.2, end: 0.0, duration: 600.ms),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Email Field
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 900.ms)
                                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 1000.ms)
                                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Remember Me & Forgot Password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              activeColor: Color(0xFF9400D8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Remember me',
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      TextButton(
                                        onPressed: () {
                                          // Handle forgot password
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Color(0xFF9400D8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 1100.ms),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF9400D8),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 8,
                                        shadowColor: Color(0xFF9400D8).withOpacity(0.3),
                                      ),
                                      child: _isLoading
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Signing In...',
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'Sign In',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ).animate()
                                    .fadeIn(duration: 600.ms, delay: 1200.ms)
                                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 600.ms)
                    .slideY(begin: 0.4, end: 0.0, duration: 800.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Link
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF9400D8).withOpacity(0.2),
                        width: 1,
                      ),
                      color: Colors.white.withOpacity(0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupPage()),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.spaceGrotesk(
                              color: Color(0xFF9400D8),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 1400.ms)
                    .slideY(begin: 0.3, end: 0.0, duration: 600.ms),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Color(0xFF9400D8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Color(0xFF9400D8).withOpacity(0.7),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF9400D8).withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFF9400D8),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      // Simulate login process
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to home page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0B2E),
              Color(0xFF2D1B3D),
              Color(0xFF503CB7),
              Color(0xFF7C6FBF),
              Color(0xFFE8E4F3),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles background
            Positioned.fill(
              child: Container(),
            ),

            // Animated Background Elements
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF503CB7).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(controller: _backgroundController)
                .rotate(duration: 30.seconds)
                .scale(begin: Offset(0.8, 0.8), end: Offset(1.2, 1.2), duration: 15.seconds)
                .then()
                .scale(begin: Offset(1.2, 1.2), end: Offset(0.8, 0.8), duration: 15.seconds),
            ),
            
            Positioned(
              bottom: -200,
              left: -200,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF7C6FBF).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(controller: _backgroundController)
                .rotate(duration: 25.seconds, begin: 1.0, end: 0.0)
                .scale(begin: Offset(1.0, 1.0), end: Offset(1.3, 1.3), duration: 20.seconds)
                .then()
                .scale(begin: Offset(1.3, 1.3), end: Offset(1.0, 1.0), duration: 20.seconds),
            ),

            // Top geometric shapes
            Positioned(
              top: 100,
              left: 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF503CB7).withOpacity(0.4),
                      Color(0xFF7C6FBF).withOpacity(0.2),
                    ],
                  ),
                ),
              ).animate(controller: _backgroundController)
                .rotate(duration: 20.seconds)
                .fadeIn(duration: 2.seconds)
                .then()
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: 0, end: -20, duration: 3.seconds),
            ),

            Positioned(
              top: 200,
              right: 80,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7C6FBF).withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(controller: _backgroundController)
                .rotate(duration: 15.seconds, begin: 1.0, end: 0.0)
                .fadeIn(duration: 3.seconds)
                .then()
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveX(begin: 0, end: 15, duration: 4.seconds),
            ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Lottie Animation with enhanced container
                      Container(
                        height: 300,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Color(0xFF7C6FBF).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Lottie.network(
                          'https://lottie.host/22697308-5499-4beb-aa1d-8a83c779c72a/tZXWQbq2pT.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 80,
                                    color: Color(0xFF7C6FBF),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'SafeVision',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF503CB7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ).animate()
                        .fadeIn(duration: 1.5.seconds)
                        .slideY(begin: -0.2, duration: 1.2.seconds, curve: Curves.easeOutBack)
                        .then()
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .moveY(begin: 0, end: -10, duration: 3.seconds),
                      
                      const SizedBox(height: 20),
                      
                      // App Title and Subtitle
                      Column(
                        children: [
                          Text(
                            'SafeVision',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    Color(0xFF1A0B2E),
                                    Color(0xFF503CB7),
                                    Color(0xFF7C6FBF),
                                  ],
                                ).createShader(Rect.fromLTWH(0.0, 0.0, 250.0, 80.0)),
                            ),
                          ).animate()
                            .fadeIn(duration: 1.5.seconds, delay: 0.3.seconds)
                            .slideX(begin: -0.3, duration: 1.0.seconds, curve: Curves.easeOutQuart)
                            .then()
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.3)),
                          
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF503CB7).withOpacity(0.3),
                                  Color(0xFF7C6FBF).withOpacity(0.4),
                                ],
                              ),
                              border: Border.all(
                                color: Color(0xFFE8E4F3).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Smart Driver Monitoring System',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A0B2E),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 1.5.seconds, delay: 0.6.seconds)
                            .slideX(begin: 0.3, duration: 1.0.seconds, curve: Curves.easeOutQuart)
                            .scale(begin: Offset(0.8, 0.8), duration: 0.8.seconds, delay: 0.8.seconds),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login Form with modern glass effect
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Color(0xFF7C6FBF).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: -5,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Text with modern styling
                              Container(
                                padding: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF503CB7).withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Welcome Back',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A0B2E),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Sign in to continue monitoring',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF503CB7),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Email Field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
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
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Password Field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
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
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Color(0xFF503CB7),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Remember me',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Color(0xFF503CB7),
                                          fontSize: 12,
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
                                        color: Color(0xFF503CB7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Login Button with modern design
                              Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1A0B2E),
                                      Color(0xFF503CB7),
                                      Color(0xFF7C6FBF),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF503CB7).withOpacity(0.4),
                                      blurRadius: 25,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
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
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sign In',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ).animate()
                                .fadeIn(duration: 1.seconds, delay: 1.2.seconds)
                                .slideY(begin: 0.3, duration: 0.8.seconds),
                            ],
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 1.2.seconds, delay: 0.8.seconds)
                        .slideY(begin: 0.3, duration: 1.seconds, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 24),
                      
                      // Sign Up Option with modern styling
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(                            "Don't have an account? ",
                            style: GoogleFonts.spaceGrotesk(
                              color: Color(0xFF503CB7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to sign up
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Color(0xFF1A0B2E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 1.2.seconds, delay: 1.8.seconds)
                        .slideY(begin: 0.3, duration: 0.8.seconds),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
            color: Color(0xFF503CB7),
            fontSize: 15,
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
            color: Color(0xFF0D1B2A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: EdgeInsets.only(left: 12, right: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF415A77).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF415A77),
                size: 20,
              ),
            ),
            suffixIcon: isPassword
                ? Container(
                    margin: EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF415A77).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Color(0xFF415A77),
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Color(0xFF778DA9).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Color(0xFF778DA9).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Color(0xFF415A77),
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Color(0xFF778DA9).withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
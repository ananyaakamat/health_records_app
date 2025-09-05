import 'package:flutter/material.dart';
import '../../../core/services/security_service.dart';
import '../../../core/themes/app_theme.dart';
import 'security_setup_screen.dart';
import 'auth_screen.dart';

class SecurityWrapperScreen extends StatefulWidget {
  const SecurityWrapperScreen({super.key});

  @override
  State<SecurityWrapperScreen> createState() => _SecurityWrapperScreenState();
}

class _SecurityWrapperScreenState extends State<SecurityWrapperScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuthentication();
  }

  Future<void> _initializeAuthentication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only check if security setup is needed
      final isSetup = await _securityService.isSecuritySetup();

      setState(() {
        _isLoading = false;
      });

      if (!isSetup) {
        _navigateToSetup();
      } else {
        _navigateToAuth();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _navigateToAuth();
    }
  }

  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SecuritySetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading ? _buildLoadingScreen() : const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 50,
              ),
            ),

            const SizedBox(height: 40),

            // App Title
            Text(
              'Health Records',
              style: AppTheme.headlineStyle.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Secure • Private • Accessible',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Animation
            Column(
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Initializing Security...',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

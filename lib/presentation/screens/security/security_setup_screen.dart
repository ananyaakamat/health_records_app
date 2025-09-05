import 'package:flutter/material.dart';
import '../../../core/services/security_service.dart';
import '../../../core/themes/app_theme.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _biometricAvailable = false;
  bool _enableBiometric = false;
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _checkBiometricAvailability();
    _animationController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _securityService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
      _enableBiometric = available;
    });
  }

  bool _isValidPin(String pin) {
    return pin.length >= 4 && pin.length <= 8 && RegExp(r'^\d+$').hasMatch(pin);
  }

  Future<void> _setupSecurity() async {
    if (_pinController.text != _confirmPinController.text) {
      _showErrorDialog('PIN codes do not match');
      return;
    }

    if (!_isValidPin(_pinController.text)) {
      _showErrorDialog('PIN must be 4-8 digits long');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _securityService.setupPin(_pinController.text);
      if (success) {
        await _securityService.setBiometricEnabled(_enableBiometric);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        _showErrorDialog('Failed to setup security. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred during setup');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Your Health Records',
                                style: AppTheme.headlineStyle.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set up PIN and biometric authentication',
                                style: AppTheme.bodyStyle.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // PIN Setup Section
                  _buildSectionTitle('Create Your PIN'),
                  const SizedBox(height: 16),

                  _buildPinField(
                    controller: _pinController,
                    label: 'Enter PIN (4-8 digits)',
                    obscureText: _obscurePin,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildPinField(
                    controller: _confirmPinController,
                    label: 'Confirm PIN',
                    obscureText: _obscureConfirmPin,
                    onVisibilityToggle: () {
                      setState(() {
                        _obscureConfirmPin = !_obscureConfirmPin;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Biometric Section
                  if (_biometricAvailable) ...[
                    _buildSectionTitle('Biometric Authentication'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _enableBiometric
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: _enableBiometric
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Biometric Login',
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use fingerprint or face unlock for quick access',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _enableBiometric,
                            onChanged: (value) {
                              setState(() {
                                _enableBiometric = value;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Setup Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setupSecurity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Complete Setup',
                              style: AppTheme.bodyStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headlineStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: TextInputType.number,
        maxLength: 8,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          counterText: '',
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textSecondaryColor,
            ),
            onPressed: onVisibilityToggle,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

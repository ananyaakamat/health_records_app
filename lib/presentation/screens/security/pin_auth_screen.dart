import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/security_service.dart';
import '../../../core/themes/app_theme.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen>
    with SingleTickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  final List<String> _enteredPin = [];
  final int _pinLength = 4;
  bool _isLoading = false;
  bool _isError = false;
  int _attempts = 0;
  final int _maxAttempts = 5;

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(digit);
        _isError = false;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      if (_enteredPin.length == _pinLength) {
        _validatePin();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _isError = false;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _validatePin() async {
    setState(() {
      _isLoading = true;
    });

    final pin = _enteredPin.join();
    final isValid = await _securityService.validatePin(pin);

    if (isValid) {
      // Success - navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // Failed authentication
      setState(() {
        _isError = true;
        _attempts++;
        _isLoading = false;
        _enteredPin.clear();
      });

      // Shake animation
      _animationController.reset();
      _animationController.forward();

      // Strong haptic feedback for error
      HapticFeedback.heavyImpact();

      if (_attempts >= _maxAttempts) {
        _showMaxAttemptsDialog();
      }
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Too Many Attempts'),
          ],
        ),
        content: Text(
          'You have exceeded the maximum number of PIN attempts. Please use biometric authentication or restart the app.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tryBiometricAuth();
            },
            child: const Text('Use Biometric'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryBiometricAuth() async {
    try {
      // Show loading state
      setState(() {
        _isLoading = true;
      });

      final available = await _securityService.isBiometricAvailable();
      final biometrics = await _securityService.getAvailableBiometrics();

      // Debug: Check biometric availability
      // print('Biometric available: $available');
      // print('Available biometric types: ${biometrics.map((e) => e.name).join(', ')}');

      if (!available) {
        setState(() {
          _isLoading = false;
        });
        _showMessage(
            'Biometric authentication is not available on this device');
        return;
      }

      if (biometrics.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showMessage(
            'No biometrics enrolled. Please set up fingerprint or face recognition in your device settings.');
        return;
      }

      // Attempting biometric authentication
      final authenticated = await _securityService.authenticateWithBiometrics();

      setState(() {
        _isLoading = false;
      });

      // Check biometric authentication result
      if (authenticated && mounted) {
        // Biometric authentication successful, navigating to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _attempts = 0; // Reset attempts after biometric failure
        });
        _showMessage(
            'Biometric authentication failed. Please try again or use your PIN.\n\nMake sure you have enrolled biometrics in your device settings.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Biometric authentication error
      _showMessage('Biometric authentication error: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _debugBiometric() async {
    try {
      final available = await _securityService.isBiometricAvailable();
      final enabled = await _securityService.isBiometricEnabled();
      final biometrics = await _securityService.getAvailableBiometrics();

      final message = '''
Debug Info:
Available: $available
Enabled: $enabled
Types: ${biometrics.map((e) => e.name).join(', ')}
Enrolled: ${biometrics.isNotEmpty}
      ''';

      _showMessage(message);
      // Debug output logged in message
    } catch (e) {
      _showMessage('Debug error: $e');
      // Debug error logged in message
    }
  }

  @override
  void dispose() {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    24,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter Your PIN',
                            style: AppTheme.headlineStyle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please enter your 4-digit PIN to access your health records',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PIN Display
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pinLength, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: index < _enteredPin.length
                                      ? (_isError
                                          ? Colors.red
                                          : AppTheme.primaryColor)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _isError
                                        ? Colors.red
                                        : index < _enteredPin.length
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _isLoading &&
                                        index == _enteredPin.length - 1
                                    ? const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : index < _enteredPin.length
                                        ? const Center(
                                            child: Icon(
                                              Icons.circle,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          )
                                        : null,
                              );
                            }),
                          ),
                        );
                      },
                    ),

                    if (_isError) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Incorrect PIN. Attempts: $_attempts/$_maxAttempts',
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Flexible(child: SizedBox(height: 15)),

                    // Number Pad
                    _buildNumberPad(),

                    const SizedBox(height: 12),

                    // Biometric Option
                    FutureBuilder<bool>(
                      future: _securityService.isBiometricAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _isLoading ? null : _tryBiometricAuth,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isLoading
                                        ? Colors.grey.withOpacity(0.3)
                                        : AppTheme.primaryColor
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isLoading)
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.fingerprint,
                                          color: AppTheme.primaryColor,
                                          size: 18,
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isLoading
                                            ? 'Authenticating...'
                                            : 'Use Biometric',
                                        style: AppTheme.bodyStyle.copyWith(
                                          color: _isLoading
                                              ? Colors.grey
                                              : AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Debug button - temporary
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _debugBiometric,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Debug Biometric',
                                    style: AppTheme.bodyStyle.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(
                  width: 65,
                  height: 65), // Empty space instead of biometric button
              _buildNumberButton('0'),
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onTap: _removeDigit,
                isVisible: _enteredPin.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(32.5),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: AppTheme.headlineStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isVisible,
  }) {
    return GestureDetector(
      onTap: isVisible ? onTap : null,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: isVisible
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(32.5),
        ),
        child: isVisible
            ? Center(
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              )
            : null,
      ),
    );
  }
}

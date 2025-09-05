import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/security_service.dart';
import '../home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  bool _isAuthenticating = false;
  bool _showPinEntry = false;
  String _statusMessage = 'Preparing authentication...';

  // PIN entry state
  final List<String> _enteredPin = [];
  final int _pinLength = 4;
  bool _isLoading = false;
  bool _isError = false;
  int _attempts = 0;
  final int _maxAttempts = 5;

  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeController.forward();

    // Start authentication process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAuthentication();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _startAuthentication() async {
    try {
      // Check if security is set up
      final isSetup = await _securityService.isSecuritySetup();
      if (!isSetup) {
        // Navigate to setup screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/setup');
        }
        return;
      }

      // Check if biometric authentication is available
      final biometricAvailable = await _securityService.isBiometricAvailable();
      final biometrics = await _securityService.getAvailableBiometrics();

      if (biometricAvailable && biometrics.isNotEmpty) {
        // Try biometric authentication first
        await _tryBiometricAuthentication();
      } else {
        // No biometrics available, show PIN entry directly
        _showPinAuthentication();
      }
    } catch (e) {
      // Authentication error - fall back to PIN
      _showPinAuthentication();
    }
  }

  Future<void> _tryBiometricAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Use your fingerprint or face to unlock';
    });

    try {
      final authenticated = await _securityService.authenticateWithBiometrics();

      if (authenticated && mounted) {
        // Success - navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Biometric failed, show PIN entry
        _showPinAuthentication();
      }
    } catch (e) {
      // Biometric authentication error - fall back to PIN
      _showPinAuthentication();
    }
  }

  void _showPinAuthentication() {
    setState(() {
      _isAuthenticating = false;
      _showPinEntry = true;
      _statusMessage = 'Enter your PIN to continue';
    });
  }

  void _retryBiometric() {
    setState(() {
      _showPinEntry = false;
      _statusMessage = 'Preparing biometric authentication...';
    });
    _tryBiometricAuthentication();
  }

  // PIN entry methods
  void _addDigit(String digit) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(digit);
        _isError = false;
      });

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
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() {
        _isError = true;
        _attempts++;
        _isLoading = false;
        _enteredPin.clear();
      });

      _shakeController.reset();
      _shakeController.forward();
      HapticFeedback.heavyImpact();

      if (_attempts >= _maxAttempts) {
        // Could add a lockout mechanism here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background: Home screen (blurred when authenticating)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _isAuthenticating || _showPinEntry
                ? Container(
                    decoration: const BoxDecoration(
                      color: Color(0xB3000000), // Colors.black.withOpacity(0.7)
                    ),
                    child: Stack(
                      children: [
                        // Blurred home screen in background
                        const Positioned.fill(
                          child: Opacity(
                            opacity: 0.3,
                            child: HomeScreen(),
                          ),
                        ),
                        // Dark overlay
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(
                                      0x99000000), // Colors.black.withOpacity(0.6)
                                  Color(
                                      0xCC000000), // Colors.black.withOpacity(0.8)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const HomeScreen(),
          ),

          // Authentication overlay
          if (_isAuthenticating || _showPinEntry)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _showPinEntry
                    ? _buildPinEntryOverlay()
                    : _buildBiometricOverlay(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBiometricOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Biometric icon with animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.fingerprint,
              color: Colors.white,
              size: 60,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            _statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Use PIN instead button
          TextButton.icon(
            onPressed: _showPinAuthentication,
            icon: const Icon(Icons.pin, color: Colors.white70),
            label: const Text(
              'Use PIN instead',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinEntryOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PIN Entry Header
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final available =
                        await _securityService.isBiometricAvailable();
                    final biometrics =
                        await _securityService.getAvailableBiometrics();

                    if (available && biometrics.isNotEmpty) {
                      _retryBiometric();
                    }
                  },
                  icon: const Icon(
                    Icons.fingerprint,
                    color: Colors.blue,
                    size: 32,
                  ),
                  tooltip: 'Try biometric again',
                ),
                const Expanded(
                  child: Text(
                    'Enter PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 16),

            // PIN dots display
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: index < _enteredPin.length
                              ? (_isError ? Colors.red : Colors.blue)
                              : Colors.white,
                          border: Border.all(
                            color: _isError
                                ? Colors.red
                                : index < _enteredPin.length
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoading && index == _enteredPin.length - 1
                            ? const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
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
                                      size: 12,
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
              const Text(
                'Incorrect PIN',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Number pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 60, height: 60),
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isVisible ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: isVisible
            ? Center(
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

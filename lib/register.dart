import 'dart:async';

import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  double passwordStrength = 0;
  String passwordError = "";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _preRegName;
  String? _preRegPhone;

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isSettingPassword = false;
  String? _message;
  int _resendSeconds = 0;
  Timer? _timer;

  void _checkPasswordStrength(String value) {
    setState(() {
      if (value.length < 6) {
        passwordStrength = 0.2;
        passwordError = "Too short";
      } else if (value.length < 10) {
        passwordStrength = 0.5;
        passwordError = "";
      } else {
        passwordStrength = 0.8;
        passwordError = "";
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validateEmailOnly() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email');
      return false;
    }
    return true;
  }

  bool _validatePasswords() {
    final pass = _passwordController.text;
    final confirm = _confirmController.text;
    if (pass.isEmpty || confirm.isEmpty) {
      setState(() => _message = 'Please enter and confirm your password');
      return false;
    }
    if (pass != confirm) {
      setState(() => _message = 'Passwords do not match');
      return false;
    }
    return true;
  }

  void _startResendTimer() {
    _resendSeconds = AuthService.secondsUntilVerificationRetry(
      _emailController.text.trim(),
    );
    _timer?.cancel();
    if (_resendSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _resendSeconds = AuthService.secondsUntilVerificationRetry(
            _emailController.text.trim(),
          );
          if (_resendSeconds <= 0) t.cancel();
        });
      });
    }
  }

  Future<void> _sendOtp() async {
    if (!_validateEmailOnly()) return;
    setState(() {
      _isSending = true;
      _message = null;
      _otpVerified = false;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final res = await AuthService.sendRegisterOtp(
      _emailController.text.trim(),
    );
    setState(() {
      _isSending = false;
      _otpSent = res.ok;
      _message = res.message;
      if (res.ok) {
        // Store pre-reg data but DON'T fill controllers yet
        // Controllers will be filled AFTER OTP verification
        _preRegName = res.name;
        _preRegPhone = res.phone;
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _message = 'Enter the OTP sent to your email');
      return;
    }
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final res = await AuthService.verifyEmailOtp(_emailController.text.trim(), otp);
    setState(() {
      _isVerifying = false;
      _otpVerified = res.ok;
      _message = res.message;
      // Fill credentials ONLY AFTER OTP verification succeeds
      if (_otpVerified) {
        if (_preRegName != null && _preRegName!.isNotEmpty) {
          _nameController.text = _preRegName!;
        }
        if (_preRegPhone != null && _preRegPhone!.isNotEmpty) {
          _phoneController.text = _preRegPhone!;
        }
      }
    });
  }

  Future<void> _setPassword() async {
    if (!_otpVerified) {
      setState(() => _message = 'Verify OTP first');
      return;
    }
    if (!_validatePasswords()) return;
    setState(() {
      _isSettingPassword = true;
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final res = await AuthService.setPasswordAfterVerification(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() {
      _isSettingPassword = false;
      _message = res.message;
    });
    if (res.ok && mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Account Ready'),
          content: const Text('Password set successfully. You can now sign in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF22232A),
              borderRadius: BorderRadius.circular(14),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "IITShelf",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  "Create Your Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  "Email",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Full Name",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Auto-filled after OTP verification',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Phone Number",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 10, right: 8),
                      child: Text(
                        "+880",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 60,
                      minHeight: 0,
                    ),
                    hintText: 'Auto-filled after OTP verification',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  readOnly: !_otpVerified,
                  onChanged: _checkPasswordStrength,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: _otpVerified
                        ? 'Create a strong password'
                        : 'Verify OTP first',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: passwordStrength,
                        backgroundColor: Colors.grey[800],
                        color: passwordStrength < 0.5
                            ? Colors.red
                            : Colors.green,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                if (passwordError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      passwordError,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(height: 14),
                Text(
                  "Confirm Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  readOnly: !_otpVerified,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: _otpVerified
                        ? 'Re-enter your password'
                        : 'Verify OTP first',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),

                SizedBox(height: 18),
                Text(
                  "Email OTP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black,
                          hintText: _otpSent
                              ? 'Enter the 6-digit code'
                              : 'Send OTP to receive code',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSending || _resendSeconds > 0
                          ? null
                          : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _resendSeconds > 0
                                  ? 'Retry in $_resendSeconds s'
                                  : 'Send OTP',
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSending || _isVerifying || _isSettingPassword)
                        ? null
                        : !_otpSent
                            ? _sendOtp
                            : !_otpVerified
                                ? _verifyOtp
                                : _setPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: (_isSending || _isVerifying || _isSettingPassword)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            !_otpSent
                                ? 'Send OTP'
                                : !_otpVerified
                                    ? 'Verify OTP'
                                    : 'Set Password & Create Account',
                          ),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey,
                    ),
                    child: Text("Back to Login"),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

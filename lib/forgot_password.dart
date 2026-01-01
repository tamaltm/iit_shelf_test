import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _otpSent = false;
  bool _isSending = false;
  bool _isResetting = false;
  bool _verified = false;
  String? _message;
  int _resendSeconds = 0;
  Timer? _timer;
  bool _obscureNew = true;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _startResendTimer(String email) {
    _resendSeconds = AuthService.secondsUntilRetry(email);
    _timer?.cancel();
    if (_resendSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _resendSeconds = AuthService.secondsUntilRetry(email);
          if (_resendSeconds <= 0) {
            t.cancel();
          }
        });
      });
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your registered email');
      return;
    }
    setState(() {
      _isSending = true;
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    final ok = AuthService.sendPasswordResetOtp(email);
    setState(() {
      _isSending = false;
      if (ok) {
        _otpSent = true;
        _message = 'OTP sent to your registered email (check console in demo).';
        _startResendTimer(email);
      } else {
        final secs = AuthService.secondsUntilRetry(email);
        if (secs > 0) {
          _message = 'Please retry after $secs seconds.';
          _startResendTimer(email);
        } else {
          _message = 'Email not found.';
        }
      }
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;
    if (email.isEmpty || otp.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _message = 'Please fill all fields');
      return;
    }
    if (newPass != confirm) {
      setState(() => _message = 'Passwords do not match');
      return;
    }
    setState(() {
      _isResetting = true;
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    final ok = AuthService.resetPassword(email, otp, newPass);
    setState(() => _isResetting = false);
    if (ok) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Password Reset'),
          content: const Text('Your password has been reset successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _message = 'Invalid or expired OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) {
      setState(() => _message = 'Please enter email and OTP');
      return;
    }
    setState(() {
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final ok = AuthService.verifyResetOtp(email, otp);
    if (ok) {
      setState(() {
        _verified = true;
        _message = 'OTP verified — please enter a new password.';
      });
    } else {
      setState(() => _message = 'Invalid or expired OTP');
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF22232A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Forgot Password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your registered institution email. An OTP will be sent to reset your password. You can retry after 1 minute.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Registered institution email',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 12),
                if (!_otpSent) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                      child: _isSending ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP'),
                    ),
                  ),
                ] else if (!_verified) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Enter OTP',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Colors.blue),
                          child: const Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _resendSeconds > 0 ? null : _sendOtp,
                        child: Text(_resendSeconds > 0 ? 'Retry in ${_resendSeconds}s' : 'Resend OTP', style: const TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _newPassController,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'New password',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPassController,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Confirm password',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isResetting ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Colors.blue),
                          child: _isResetting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset Password'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

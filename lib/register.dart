import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool agreed = false;
  double passwordStrength = 0;
  String passwordError = "";

  final TextEditingController _passwordController = TextEditingController();

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
    _passwordController.dispose();
    super.dispose();
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
                        color: Colors.white),
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  "Create Your Account",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 18),
                Text(
                  "Full Name",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                SizedBox(height: 6),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  "Email",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                SizedBox(height: 6),
                TextFormField(
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
                  "Phone Number",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                SizedBox(height: 6),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 60, minHeight: 0),
                    hintText: 'Your phone number',
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
                      fontSize: 15),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  onChanged: _checkPasswordStrength,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Create a strong password',
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
                        color: passwordStrength < 0.5 ? Colors.red : Colors.green,
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
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                SizedBox(height: 14),
                Text(
                  "Confirm Password",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                SizedBox(height: 6),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Re-enter your password',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Checkbox(
                      value: agreed,
                      activeColor: Colors.blueAccent,
                      onChanged: (value) {
                        setState(() {
                          agreed = value ?? false;
                        });
                      },
                    ),
                    Flexible(
                      child: Wrap(
                        children: [
                          Text(
                            "I agree to the ",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {}, // Add your link handler
                            child: Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                          Text(
                            " and Privacy Policy.",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: agreed ? () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey,
                    ),
                    child: Text("Register"),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text("Login", style: TextStyle(color: Colors.blue)),
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

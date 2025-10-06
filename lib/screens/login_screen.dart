import 'package:flutter/material.dart';
import 'package:vendwise/screens/dashboard_screen.dart';
import 'package:vendwise/screens/sign_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD74848), Color(0xFF111C51)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 200, height: 250),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.elliptical(45, 45),
                          topRight: Radius.elliptical(45, 45),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Hello! User',
                            style: TextStyle(
                              fontSize: 30.0,
                              color: Color(0xFF202756),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: "Gmail",
                                labelStyle: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4D0202),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter username";
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Password",
                                labelStyle: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4D0202),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter password";
                                }
                                if (value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: .6,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.red,
                                        checkColor: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "Remember Me",
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        color: Color(0xFF4D0202),
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      color: Color(0xFF4D0202),
                                      fontSize: 10.0,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD74848), Color(0xFF1C36B5)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(250, 50),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: const BorderSide(color: Colors.white, width: 1),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 60,
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const DashboardScreen()),
                                  );
                                }
                              },
                              child: const Text(
                                'LOGIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Don't Have an Account?",
                                    style: TextStyle(
                                      fontFamily: "Inter",
                                      color: Colors.black,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SignInScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "SIGN IN",
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        color: Color(0xFF4D0202),
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

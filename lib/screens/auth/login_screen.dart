import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/models/app_user.dart';
import 'package:vendwise/screens/auth/reset_password_screen.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/auth/sign_screen.dart';
import 'package:vendwise/services/app_session.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _rememberMe = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _hydrateRememberedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _hydrateRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('login_remember_me') ?? false;
    final rememberedUsername = prefs.getString('login_username');

    // Clean up any previously stored password for safety.
    if (prefs.containsKey('login_password')) {
      await prefs.remove('login_password');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberMe = remembered;
      if (remembered) {
        if (rememberedUsername != null) {
          _usernameController.text = rememberedUsername;
        }
      }
    });
  }

  Future<void> _persistRememberedCredentials(
    bool remember, {
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setBool('login_remember_me', true);
      if (username != null) {
        await prefs.setString('login_username', username);
      }
    } else {
      await prefs.setBool('login_remember_me', false);
      await prefs.remove('login_username');
      await prefs.remove('login_password');
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final AppUser? user = await appRepository.authenticate(
        username,
        password,
      );

      if (!mounted) {
        return;
      }

      if (user == null) {
        setState(() {
          _errorMessage = 'Invalid credentials or inactive account.';
        });
        return;
      }

      if (supabaseRepositoryActive) {
        final serviceEmail = supabaseServiceEmail?.trim();
        final servicePassword = supabaseServicePassword;

        if (serviceEmail == null || serviceEmail.isEmpty) {
          setState(() {
            _errorMessage =
                'Supabase is enabled but SUPABASE_SERVICE_EMAIL is missing.';
          });
          return;
        }
        if (servicePassword == null || servicePassword.isEmpty) {
          setState(() {
            _errorMessage =
                'Supabase is enabled but SUPABASE_SERVICE_PASSWORD is missing.';
          });
          return;
        }

        try {
          final auth = Supabase.instance.client.auth;
          final Session? session = auth.currentSession;
          final currentEmail = session?.user.email?.trim().toLowerCase();
          final targetEmail = serviceEmail.toLowerCase();

          if (session == null || currentEmail != targetEmail) {
            await auth.signOut();
            await auth.signInWithPassword(
              email: serviceEmail,
              password: servicePassword,
            );
          }
        } on AuthException catch (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorMessage = 'Supabase sign-in failed: ${error.message}';
          });
          return;
        } catch (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorMessage = 'Supabase sign-in failed: $error';
          });
          return;
        }
      }

      if (!mounted) {
        return;
      }
      AppHaptics.mediumImpact();
      await AppSession.instance.setUser(user);
      await _persistRememberedCredentials(_rememberMe, username: username);
      if (!mounted) {
        return;
      }
      pushAndRemoveUntilWithSlide<void>(context, const DashboardScreen());
    } catch (error) {
      setState(() {
        _errorMessage = 'Login failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD74848), Color(0xFF111C51)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Image.asset('assets/icons/logo.png', width: 300, height: 320),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Hello! User',
                                style: TextStyle(
                                  fontSize: 30.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF202756),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocusNode);
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Email or Username',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4D0202),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4D0202),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: .8,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (bool? value) {
                                            final next = value ?? false;
                                            setState(() {
                                              _rememberMe = next;
                                            });
                                            if (!next) {
                                              _persistRememberedCredentials(
                                                false,
                                              );
                                            }
                                          },
                                          activeColor: const Color(0xFFD74848),
                                          checkColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Remember Me',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF4D0202),
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      AppHaptics.selectionChanged();
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final recoveredUsername =
                                          await pushWithSlide<String?>(
                                            context,
                                            const ResetPasswordScreen(),
                                          );
                                      if (!mounted) {
                                        return;
                                      }
                                      if (recoveredUsername != null &&
                                          recoveredUsername.isNotEmpty) {
                                        _usernameController.text =
                                            recoveredUsername;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Password updated. Please sign in with your new credentials.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF4D0202),
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFD74848),
                                      Color(0xFF1C36B5),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(250, 52),
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 60,
                                    ),
                                  ),
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'LOGIN',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Don't Have an Account?",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.black,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () async {
                                        AppHaptics.selectionChanged();
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final created =
                                            await pushWithSlide<bool?>(
                                              context,
                                              const SignInScreen(),
                                            );
                                        if (!mounted) {
                                          return;
                                        }
                                        if (created == true) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Account created. Please log in.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF4D0202),
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}

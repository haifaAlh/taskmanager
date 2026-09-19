import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// استبدل هذا المسار بمسار صفحة الرئيسية لديك داخل مشروع taskmanager
import 'package:taskmanager/pages/mainScreen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordObscured = true;

  // متغيرات الأخطاء
  String? emailError;
  String? passwordError;
  String? usernameError;
  String? nicknameError;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // الحصول على كائن Supabase Client المباشر
  final SupabaseClient _supabase = Supabase.instance.client;

  void _clearErrors() {
    setState(() {
      emailError = null;
      passwordError = null;
      usernameError = null;
      nicknameError = null;
    });
  }

  // دالة التعامل مع تسجيل الدخول وإنشاء الحساب بـ Supabase مباشرة
  Future<void> _handleAuth() async {
    _clearErrors();

    if (!isLogin) {
      if (_nicknameController.text.trim().isEmpty) {
        setState(() => nicknameError = "Nickname is required");
        return;
      }
      if (_usernameController.text.trim().isEmpty) {
        setState(() => usernameError = "Username is required");
        return;
      }
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => emailError = "Email is required");
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => passwordError = "Password is required");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // إرسال البيانات إلى data لتلتقطها الدالة handle_new_user في Supabase
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'username': _usernameController.text.trim(),
            'nickname': _nicknameController.text.trim(),
          },
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        String msg = e.message.toLowerCase();
        if (msg.contains("username") ||
            msg.contains("error saving new user") ||
            msg.contains("23505")) {
          usernameError = "This username is already taken";
        } else if (msg.contains("already registered") ||
            msg.contains("email")) {
          emailError = "This email is already registered";
        } else {
          emailError = e.message;
        }
      });
    } catch (e) {
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains("username") || errorStr.contains("23505")) {
        setState(() => usernameError = "This username is already taken");
      } else {
        setState(() => emailError = "An error occurred: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5B32E4);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header Texts
              Text(
                isLogin ? 'Welcome Back! 👋' : 'Create Account 🚀',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLogin
                    ? 'Sign in to continue'
                    : 'Fill in the details to get started',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Illustration Header
              Center(
                child: SizedBox(
                  height: 160,
                  child: Image.asset(
                    'assets/images/auth_illustration.png',
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_pin_rounded,
                      size: 100,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Bar (Login / Sign Up)
              _buildTabBar(primaryColor),
              const SizedBox(height: 24),

              // Form Inputs
              if (!isLogin) ...[
                _buildInputField(
                  label: "Nickname",
                  hint: "Enter your nickname",
                  icon: Icons.badge_outlined,
                  controller: _nicknameController,
                  errorText: nicknameError,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: "Username",
                  hint: "Enter your username",
                  icon: Icons.person_outline,
                  controller: _usernameController,
                  errorText: usernameError,
                ),
                const SizedBox(height: 16),
              ],

              _buildInputField(
                label: "Email",
                hint: "Enter your email",
                icon: Icons.email_outlined,
                controller: _emailController,
                errorText: emailError,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                label: "Password",
                hint: "Enter your password",
                icon: Icons.lock_outline,
                controller: _passwordController,
                isPassword: true,
                errorText: passwordError,
              ),

              // Forgot Password Link
              if (isLogin) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLogin ? "Login" : "Sign Up",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider "or continue with"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // Social Logins
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      label: "Google",
                      iconWidget: const Icon(Icons.g_mobiledata,
                          size: 28, color: Colors.red),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      label: "Apple",
                      iconWidget: const Icon(Icons.apple,
                          size: 22, color: Colors.black),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _clearErrors();
                  setState(() => isLogin = true);
                },
                child: Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLogin ? primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _clearErrors();
                  setState(() => isLogin = false);
                },
                child: Center(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !isLogin ? primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 2,
              color: Colors.grey.shade200,
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionalTranslation(
                translation: Offset.zero,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.43,
                  height: 2,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  errorText != null ? Colors.redAccent : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && isPasswordObscured,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordObscured = !isPasswordObscured;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

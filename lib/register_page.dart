// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'utility/routerboardservice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'component/textfield_design.dart';
import 'component/button_design.dart';
import 'forgetpassword.dart';
import 'screens/verification_code.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final RouterboardService _routerboardService = RouterboardService();


  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        direction: TextDirection.rtl,
        title: const Text('كلمات المرور غير متطابقة'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var response = await _routerboardService.registerUser({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'phone': _phoneController.text,
      });

      if (response['status'] == 'success') {
        // Save user data in SharedPreferences
        prefs.setString('name', _nameController.text);
        prefs.setString('email', _emailController.text);
        prefs.setString('password', _passwordController.text);
        // Navigate to Verification Code Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerificationCodeScreen(email: _emailController.text)),
        );
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          direction: TextDirection.rtl,
          title: const Text('تم التسجيل بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else {
        // Handle known API error codes
        String errorMsg = response['message'] ?? 'حدث خطأ غير متوقع';
        if (response['status_code'] == 409) {
          errorMsg = 'البريد الإلكتروني مسجل بالفعل';
        }
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: Text(errorMsg),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        direction: TextDirection.rtl,
        title: Text('خطأ: $e'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }

    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل جديد', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0D47A1), // Dark blue background color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF0D47A1), // Dark blue background color
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 60), // Space after the logo
                Container(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'تسجيل جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1), // Dark blue text color
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'الاسم',
                        hintColor: Colors.grey,
                        icon: Icons.person,
                        iconColor: Colors.black,
                        obscureText: false,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'البريد الإلكتروني',
                        hintColor: Colors.grey,
                        icon: Icons.mail,
                        iconColor: Colors.black,
                        obscureText: false,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'كلمة المرور',
                        hintColor: Colors.grey,
                        icon: Icons.lock,
                        iconColor: Colors.black,
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'تأكيد كلمة المرور',
                        hintColor: Colors.grey,
                        icon: Icons.lock,
                        iconColor: Colors.black,
                        obscureText: true,
                        controller: _confirmPasswordController,
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'رقم الهاتف',
                        hintColor: Colors.grey,
                        icon: Icons.phone,
                        iconColor: Colors.black,
                        obscureText: false,
                        controller: _phoneController,
                      ),
                      const SizedBox(height: 20),
                      ButtonDesign(
                        text: 'تسجيل',
                        onPressed: _register,
                        color: const Color(0xFF0D47A1),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconData: Icons.login,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Forgetpassword(),
                                )
                                , (route) => false);
                            },
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

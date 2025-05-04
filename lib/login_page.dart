// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'dashboard.dart';
import 'register_page.dart';
import 'forgetpassword.dart';
import 'component/textfield_design.dart';
import 'component/button_design.dart';
import 'utility/routerboardservice.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final RouterboardService _service =
  RouterboardService(); // Create an instance of the service

  @override
  void initState() {
    super.initState();
    checkIfAlreadyLoggedIn();
    loadEmail();
  }

  Future<void> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    var prefs = await SharedPreferences.getInstance();

    if (email.isEmpty || password.isEmpty) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
        direction: TextDirection.rtl,
        title: const Text('يرجى ملء جميع الحقول'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }
    prefs.setString('password', password);
    setState(() {
      _isLoading = true;
    });

    try {
      var jsonResponse = await _service.login(email, password);

      if (jsonResponse['status'] == 'success' && jsonResponse['status_code'] == 200 && jsonResponse['data'] != null) {
        final data = jsonResponse['data'];
        // Save user data from response['data']
        prefs.setString('id', data['id'] ?? '');
        prefs.setString('name', data['name'] ?? '');
        prefs.setString('email', data['email'] ?? '');
        prefs.setString('password', password);
        prefs.setString('phone', data['phone'] ?? '');
        prefs.setString('serialNumber', data['serialNumber'] ?? '');
        prefs.setString('allowedDevice', data['allowedDevice'] ?? '');
        prefs.setString('expiredate', data['expiredate'] ?? '');
        prefs.setString('mikrotikIp', data['mikrotikIp'] ?? '');
        prefs.setString('mikrotikPort', data['mikrotikPort'] ?? '');
        prefs.setString('mikrotikUsername', data['mikrotikUsername'] ?? '');
        prefs.setString('mikrotikPassword', data['mikrotikPassword'] ?? '');
        prefs.setString('location', data['location'] ?? '');
        prefs.setString('networkName', data['networkName'] ?? '');
        prefs.setBool('isLoggedIn', true);

        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          direction: TextDirection.rtl,
          title: Text(jsonResponse['message'] ?? 'تم تسجيل الدخول بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else if (jsonResponse['status'] == 'success' && jsonResponse['status_code'] == 200 && jsonResponse['data'] == null) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: const Text('بيانات الاستجابة غير صالحة أو فارغة'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      } else {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: Text(jsonResponse['message'] ?? 'حدث خطأ غير متوقع'),
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
      _isLoading = false;
    });
  }

  void checkIfAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn != null && isLoggedIn) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF0D47A1),
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Image.asset(
                  'assets/images/mikrotik-logo2.png',
                  height: height * 0.1,
                  color: Colors.white,
                ),
                SizedBox(height: height * 0.02),
                Container(
                  padding: EdgeInsets.all(width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      TextFieldDesign(
                        hintText: 'البريد الإلكتروني',
                        hintColor: Colors.grey,
                        icon: Icons.mail,
                        iconColor: Colors.grey,
                        obscureText: false,
                        controller: _emailController,
                      ),
                      SizedBox(height: height * 0.02),
                      TextFieldDesign(
                        hintText: 'كلمة المرور',
                        hintColor: Colors.grey,
                        icon: Icons.lock,
                        iconColor: Colors.grey,
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      SizedBox(height: height * 0.02),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ButtonDesign(
                        text: 'تسجيل الدخول',
                        onPressed: _login,
                        color: Colors.blue[900]!,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconData: Icons.login,
                      ),
                      SizedBox(height: height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Forgetpassword(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'نسيت كلمة المرور',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'حساب جديد',
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

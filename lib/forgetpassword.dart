import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';
import 'dart:convert';

import 'component/textfield_design.dart';
import 'component/button_design.dart';
import 'login_page.dart';
import 'screens/verification_code.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({Key? key}) : super(key: key);

  @override
  _ForgetpasswordState createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final TextEditingController _phoneNumberController = TextEditingController();

  Future<void> _requestPasswordReset() async {
    setState(() {
    });

    var response = await http.post(
      Uri.parse('https://aywa.sd/api/forgetPassword'),
      body: {
        'phone': _phoneNumberController.text,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        // Navigate to VerificationCodeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerificationCodeScreen(email: _phoneNumberController.text)),
        );
      } else {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: const Text('المعذرة حدث خطأ'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } else {
      // Handle network error
      print('Network error');
    }

    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('نسيت كلمة المرور'),
        backgroundColor: const Color(0xFF0D47A1), // لون الخلفية الأزرق الداكن
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        color: const Color(0xFF0D47A1), // لون الخلفية الأزرق الداكن
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 5), // مساحة بيضاء في الأعلى
                Image.asset(
                  'assets/images/mikrotik-logo2.png',
                  height: 100,
                  color: Colors.white,
                ), // الشعار
                const SizedBox(height: 35), // مساحة بعد الشعار
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'نسيت كلمة المرور',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1), // لون النص الأزرق الداكن
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFieldDesign(
                        hintText: 'رقم الهاتف',
                        hintColor: Colors.grey,
                        icon: Icons.phone,
                        iconColor: Colors.grey,
                        obscureText: false,
                        controller: _phoneNumberController,
                      ),
                      const SizedBox(height: 20),
                      ButtonDesign(
                        text: 'إعادة تعيين كلمة المرور',
                        onPressed: _requestPasswordReset,
                        color: const Color(0xFF0D47A1),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconData: Icons.password,
                      ),
                      const SizedBox(height: 20),
                      ButtonDesign(
                        text: 'تذكرت كلمة المرور؟',
                        onPressed: () async {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        color: const Color(0xFF0D47A1),
                        textColor: Colors.white,
                        iconColor: Colors.white,
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'component/button_design.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? email;
  String? password;
  String? phone;
  String? name;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    password = prefs.getString('password');
    phone = prefs.getString('phone');
    name = prefs.getString('name');

    setState(() {
      _nameController.text = name ?? 'عيد الرحمن مولود';
      _emailController.text = email ?? 'example@gmail.com';
      _phoneController.text = phone ?? '0599999999';
    });
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final Map<String, String> body = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': password!,
        };

        if (_passwordController.text.isNotEmpty) {
          body['password'] = _passwordController.text;
        }

        final response = await http.post(
          Uri.parse('https://aywa.sd/api/updateProfileData'),
          body: body,
        );

        if (response.statusCode == 200) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', _nameController.text);
          await prefs.setString('email', _emailController.text);
          await prefs.setString('phone', _phoneController.text);

          if (_passwordController.text.isNotEmpty) {
            await prefs.setString('password', _passwordController.text);
          }

          toastification.show(
            context: context,
            style: ToastificationStyle.fillColored,
            type: ToastificationType.success,
            alignment: Alignment.bottomCenter,
            title: const Text('تم تحديث البيانات بنجاح'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else {
          toastification.show(
            context: context,
            style: ToastificationStyle.fillColored,
            type: ToastificationType.error,
            alignment: Alignment.bottomCenter,
            title: const Text('فشل تحديث البيانات'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          alignment: Alignment.bottomCenter,
          title: const Text('حدث خطأ غير متوقع'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } finally {
        Navigator.pop(context); // Close the loading dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.blue[900],
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        color: Colors.blue[900],
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            labelStyle: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال الاسم';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            labelStyle: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال البريد الإلكتروني';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            labelStyle: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            hintText: 'اتركها فارغة إذا لم ترد تغييرها',
                            labelStyle: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ButtonDesign(
                          text: 'حفظ',
                          onPressed: _saveProfileData,
                          color: Colors.blue,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          iconData: Icons.save,
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
    );
  }
}

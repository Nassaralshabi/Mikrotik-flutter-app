import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'component/button_design.dart';
import 'settings.dart';
import 'utility/routerboardservice.dart';

class ActivationRequest extends StatefulWidget {
  const ActivationRequest({Key? key}) : super(key: key);

  @override
  _ActivationRequestState createState() => _ActivationRequestState();
}

class _ActivationRequestState extends State<ActivationRequest> {
  final RouterboardService _service = RouterboardService(); // Create an instance of the service

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    saveRequestActivationStatus();
  }

  Future<void> saveRequestActivationStatus() async {
    // prefs.setBool('requestActivation', true);
  }

  Future<void> _refreshStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    print(email);
    print(password);
    var jsonResponse = await _service.login(email!, password!);
    print(jsonResponse);
    if (jsonResponse['status'] == 'success') {
      prefs.setBool('isLoggedIn', true);
      prefs.setBool('requestActivation', false);
      prefs.setString('name', jsonResponse['data']['name']);
      prefs.setString('phone', jsonResponse['data']['phone']);
      prefs.setString('password', password);
      if(jsonResponse['data']['expiredate'] == null) {
        prefs.setString('expiredate', jsonResponse['data']['expiredate']);
      }
      // check if the user is expired or not based on the expiredate
      DateTime expireDate = DateTime.parse(jsonResponse['data']['expiredate']);
      DateTime currentDate = tz.TZDateTime.now(tz.getLocation('Africa/Khartoum'));

      // based on this 2024-08-31 format of the expiredate we can compare the dates
      if (currentDate.isAfter(expireDate)) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          alignment: Alignment.topCenter,
          direction: TextDirection.rtl,
          title: const Text('الحساب منتهي'),
          autoCloseDuration: const Duration(seconds: 2),
        );
        // user is expired set isExpired to true
        prefs.setBool('isExpired', true);
      } else {
        // user is not expired set isExpired to false
        prefs.setBool('isExpired', false);
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          alignment: Alignment.topCenter,
          direction: TextDirection.rtl,
          title: const Text('تم التفعيل بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );
        // navigate to the settings page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final screenHeight = mediaQuery.size.height - padding.top - padding.bottom;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF0D47A1), // Dark blue background color
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ListView(
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.1), // Space after the logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'طلب تفعيل الخدمة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1), // Dark blue text color
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        ButtonDesign(
                          text: 'التواصل مع الإدارة',
                          onPressed: () async {
                            await launchUrl(
                              Uri.parse('https://wa.me/249912740956'),
                            );
                          },
                          color: Colors.blue,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ButtonDesign(
                          text: 'تحديث الحالة',
                          onPressed: _refreshStatus,
                          color: Colors.green,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ButtonDesign(
                          text: 'خروج',
                          onPressed: () {
                            final prefs = SharedPreferences.getInstance();
                            prefs.then((value) {
                              value.clear();
                            });
                            exit(0);
                          },
                          color: Colors.red,
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
      ),
    );
  }
}

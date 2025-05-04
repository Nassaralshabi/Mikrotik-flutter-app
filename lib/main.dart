import 'package:Aywa/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'activation_request.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'utility/routerboardservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Workmanager on Android/iOS, not on web or desktop
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await _initializeApp();
  }

  runApp(MyApp());
}

Future<void> _initializeApp() async {
  await _requestPermissions();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool isFirstRun = prefs.getBool('firstRun') ?? true;
  String? mikrotikIp = prefs.getString('mikrotikIp');
  bool requestActivation = prefs.getBool('requestActivation') ?? false;

  Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    "1",
    "deleteExpiredUsersTask",
    frequency: const Duration(minutes: 15),
    inputData: {
      'mikrotikIp': mikrotikIp ?? '',
    },
  );

  prefs.setBool('isFirstRun', isFirstRun);
  prefs.setBool('requestActivation', requestActivation);
}

Future<void> _requestPermissions() async {
}

void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    String? mikrotikIp = inputData?['mikrotikIp'];

    if (mikrotikIp != null && mikrotikIp.isNotEmpty) {
      RouterboardService routerboardService = RouterboardService();
      var expiredUsers = await routerboardService.fetchExpiredUsers();
      for (var user in expiredUsers) {
        await routerboardService.deleteUser(user['.id']);
      }
    }

    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          return MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', ''),
              Locale('en', ''),
            ],
            locale: const Locale('ar'),
            debugShowCheckedModeBanner: false,
            home: snapshot.data as Widget,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              fontFamily: 'Tajawal',
            ),
          );
        }
      },
    );
  }

  Future<Widget> _getInitialRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool requestActivation = prefs.getBool('requestActivation') ?? false;
    if(requestActivation) {
      VersionCheckScreen();
      return const ActivationRequest();
    } else {
      VersionCheckScreen();
      return const LoginPage();
    }
  }
}

class VersionCheckScreen extends StatefulWidget {
  const VersionCheckScreen({Key? key}) : super(key: key);

  @override
  _VersionCheckScreenState createState() => _VersionCheckScreenState();
}

class _VersionCheckScreenState extends State<VersionCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkMikrotikIpAndVersion();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _checkMikrotikIpAndVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mikrotikIp = prefs.getString('mikrotikIp');
    String? serialNumber = prefs.getString('serial-number');
    String? email = prefs.getString('email');

    if(email == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } else {
      if (mikrotikIp == null || mikrotikIp.isEmpty || serialNumber == null || serialNumber.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      } else {
        await _checkVersion();
      }
    }


  }

  Future<void> _checkVersion() async {
    final response = await http.post(Uri.parse('https://aywa.sd/api/lastVersion'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final latestVersion = data['version'];
      final message = data['message'];
      final url = data['update_url'];

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (currentVersion.compareTo(latestVersion) < 0) {
        if (mounted) {
          _showUpdateDialog(message, url);
        }
      } else {
        _navigateToNextScreen();
      }
    }
  }

  void _showUpdateDialog(String message, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحديث البرنامج'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('خروج'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                launchUrl(Uri.parse(url));
              },
              child: const Text('تحديث'),
            ),
          ],
        );
      },
    ).then((_) async {
      if (mounted) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('firstRun', false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    });
  }

  void _navigateToNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('firstRun', false);
    if (prefs.getString('serial-number') == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  }
}

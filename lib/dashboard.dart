import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deviceinfo.dart';
import 'drawer.dart';
import 'utility/routerboardservice.dart';
import 'component/device_card.dart';
import 'utility/utility.dart';
import 'screens/active_users_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}

Future<String> getUsersCount() async {
  final RouterboardService routerboardService = RouterboardService();
  return routerboardService.getUsersCount().toString();
}

Future<Map<String, String?>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? name = prefs.getString('name');
  final String? email = prefs.getString('email');
  final String? phone = prefs.getString('phone');
  return {
    'name': name,
    'email': email,
    'phone': phone,
  };
}

class DashboardScreen extends StatelessWidget {
  final RouterboardService _routerboardService = RouterboardService();
  final Utility utility = Utility();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final cardWidth = isLandscape ? (screenWidth / 3) - 40 : (screenWidth /
        1.5) - 30;
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('الرئيسية'),
        backgroundColor: Colors.blue[900],
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: MyDrawer(),
      body: SafeArea(
        child: Container(
          color: Colors.blue[900],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FutureBuilder<Map<String, String?>>(
                    future: getUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      } else if (snapshot.hasError) {
                        return const Text(
                          'حدث خطأ',
                          style: TextStyle(
                            
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        final userData = snapshot.data;
                        final username = userData?['name'] ?? 'غير معروف';
                        return Text(
                          'مرحباً بك، $username',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
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
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                FutureBuilder<String>(
                                  future: _routerboardService
                                      .getActiveUsersCount(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else {
                                      final activeUsersCount = snapshot.data ??
                                          '0';
                                      return DeviceCard(
                                        color: Colors.green,
                                        icon: Icons.verified_user,
                                        title: 'الأجهزة النشطة',
                                        subtitle: 'عدد الأجهزة النشطة',
                                        status: '$activeUsersCount جهاز',
                                        width: cardWidth,
                                        height: 200,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ActiveUsers(),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 20),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: _routerboardService
                                      .fetchRouterboardInfo(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else {
                                      final data = snapshot.data;
                                      return DeviceCard(
                                        color: Colors.lightBlueAccent,
                                        icon: Icons.info,
                                        title: 'معلومات الجهاز',
                                        subtitle: '',
                                        status: 'الموديل: ${data!['model']}',
                                        width: cardWidth,
                                        height: 200,
                                        onTap: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DeviceInfo(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                      );
                                    }
                                  },
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
            ],
          ),
        ),
      ),
    );
  }



}

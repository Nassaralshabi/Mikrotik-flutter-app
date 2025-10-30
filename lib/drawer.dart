import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'voucher_screen.dart';
import 'profilescreen.dart';
import 'login_page.dart';
import 'settings.dart';
import 'plan.dart';
import 'vouchergeneratorscreen.dart';
import 'dashboard.dart';
import 'aboutus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'deletevouchers.dart';

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
      _email = prefs.getString('email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(
                  _name,
                  style: const TextStyle(color: Colors.white),
                ),
                accountEmail: Text(_email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Image.asset('assets/images/avatar.png'),
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D47A1),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    buildListTile(
                      context,
                      title: "الرئيسية",
                      icon: Icons.home,
                      targetScreen: DashboardScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "الباقات",
                      icon: Icons.group,
                      targetScreen: PlanScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "الكروت",
                      icon: Icons.payment,
                      targetScreen: VoucherScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "مولد الكروت",
                      icon: Icons.payment,
                      targetScreen: VoucherGeneratorScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "حذف الكروت",
                      icon: Icons.delete,
                      targetScreen: DeleteVouchersScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "الإعدادات",
                      icon: Icons.settings,
                      targetScreen: SettingsScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "الملف الشخصي",
                      icon: Icons.person,
                      targetScreen: ProfileScreen(),
                    ),
                    buildListTile(
                      context,
                      title: "من نحن",
                      icon: Icons.info,
                      targetScreen: const AboutUs(),
                    ),
                    ListTile(
                      title: const Text("تواصل معنا على الواتساب"),
                      leading: const Icon(Icons.phone, color: Colors.green),
                      onTap: () async {
                        await launchUrl(
                          Uri.parse(
                            'https://wa.me/249773114243?text='
                                'السلام عليكم ورحمة الله وبركاته\n'
                                'تواصل بخصوص تطبيق ايوا\n',
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("خروج"),
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      onTap: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        var email = prefs.getString('email');
                        await prefs.clear();
                        await prefs.setString('email', email!);
                        await prefs.setBool('firstRun', false);

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (BuildContext context) => const LoginPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'جميع الحقوق محفوظة © 2024\nEng: Nassar Alshabi\n773114243',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildListTile(BuildContext context,
      {required String title,
        required IconData icon,
        required Widget targetScreen}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      leading: Icon(icon, color: Colors.blue),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => targetScreen,
        ));
      },
    );
  }
}

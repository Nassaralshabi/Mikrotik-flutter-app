import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utility/routerboardservice.dart';
import 'package:toastification/toastification.dart';
import 'drawer.dart';
import 'component/pricing_card.dart';
import 'newplanscreen.dart';

class PlanScreen extends StatefulWidget {
  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late Future<List<dynamic>> hotspotProfiles;
  final routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    hotspotProfiles = routerboardService.fetchHotspotProfiles();
  }

  void _navigateToAddNewPlan() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => NewPlanScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'), // Arabic
        Locale('en', 'US'), // English
      ],
      locale: const Locale('ar'), // Set default locale to Arabic
      home: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('الباقات'),
          backgroundColor: Colors.blue[900],
          titleTextStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToAddNewPlan,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  // refresh
                  hotspotProfiles = routerboardService.fetchHotspotProfiles();

                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
        drawer: MyDrawer(),
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
                    child: FutureBuilder<List<dynamic>>(
                      future: hotspotProfiles,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('خطأ: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('لا توجد بيانات'));
                        } else {
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              var profile = snapshot.data![index];
                              var profileColors = [
                                Colors.blueGrey,
                                Colors.blueAccent,
                                Colors.green,
                                Colors.orange,
                                Colors.purple,
                                Colors.pink,
                                Colors.teal,
                                Colors.amber,
                                Colors.brown,
                                Colors.cyan,
                                Colors.deepOrange,
                                Colors.deepPurple,
                                Colors.indigo,
                                Colors.lime,
                                Colors.red
                              ];

                              var profileIcons = [
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership,
                                Icons.card_membership
                              ];
                              return Dismissible(
                                key: Key(profile['name'] ?? 'بدون اسم'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'حذف',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(Icons.delete, color: Colors.white),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: const Text(
                                            'هل أنت متأكد من حذف هذا الملف؟'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('لا'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('نعم'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) async {
                                  bool success =
                                      await routerboardService.deleteProfile(
                                          profile['.id'], profile['name']);
                                  if (success) {
                                    toastification.show(
                                      context: context,
                                      style: ToastificationStyle.minimal,
                                      alignment: Alignment.bottomCenter,
                                      type: ToastificationType.success,
                                      direction: TextDirection.rtl,
                                      title: const Text('تم حذف الباقة بنجاح'),
                                      autoCloseDuration:
                                          const Duration(seconds: 2),
                                    );
                                  } else {
                                    toastification.show(
                                      context: context,
                                      style: ToastificationStyle.minimal,
                                      type: ToastificationType.error,
                                      direction: TextDirection.rtl,
                                      title: const Text('حدث خطأ غير متوقع'),
                                      autoCloseDuration:
                                          const Duration(seconds: 2),
                                    );
                                  }
                                },
                                child: Card(
                                  margin: const EdgeInsets.all(10.0),
                                  child: PricingCard(
                                    color: profileColors[
                                        index % profileColors.length],
                                    icon: profileIcons[
                                        index % profileIcons.length],
                                    plan:'${profile['name'] ?? 'بدون اسم'}',
                                    features: [
                                      'السرعة: ${profile['rate-limit'] ?? 'غير محدودة'}',
                                      'الأجهزة المشاركة: ${profile['shared-users'] ?? 'غير محدودة'}',

                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

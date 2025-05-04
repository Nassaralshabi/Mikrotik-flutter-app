import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'drawer.dart';
import 'utility/utility.dart';
import 'package:toastification/toastification.dart';
import 'utility/routerboardservice.dart';

class DeleteVouchersScreen extends StatefulWidget {
  @override
  _DeleteVouchersScreenState createState() => _DeleteVouchersScreenState();
}

Utility utility = Utility();

class _DeleteVouchersScreenState extends State<DeleteVouchersScreen> {
  List<dynamic> expiredUsers = [];
  Timer? _timer;
  final RouterboardService _routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadData();
    _timer = Timer.periodic(const Duration(minutes: 2), (Timer t) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final List<dynamic> data = (await _routerboardService.fetchExpiredUsers());
      setState(() {
        expiredUsers = data;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showConfirmationDeleteAll() {
    if (expiredUsers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف جميع الكروت المنتهية؟'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  deleteAllExpiredUsers();
                  Navigator.of(context).pop();
                },
                child: const Text('حذف'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showConfirmationDialog(String userId,String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الكرت؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                deleteUser(userId);
                Navigator.of(context).pop();
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _routerboardService.deleteUser(userId);
      _loadData();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> deleteAllExpiredUsers() async {
    try {
      await _routerboardService.deleteAllExpiredUsers(expiredUsers);
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('نجاح'),
        description: const Text('تم حذف جميع المستخدمين المنتهية صلاحيتهم'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      _loadData(); // تأكد من إعادة تحميل البيانات بعد الحذف
    } catch (e) {
      print('Error deleting all expired users: $e');
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('خطأ غير متوقع'),
        description: const Text('حدث خطأ غير متوقع عند حذف جميع المستخدمين'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
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
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      locale: const Locale('ar'), // Set default locale to Arabic
      home: Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'حذف الكروت المنتهية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue[900],
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.pop(context);
              },
              iconSize: 30,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showConfirmationDeleteAll(),
              iconSize: 30,
            ),
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
                      future: _routerboardService.fetchExpiredUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('لا توجد بيانات'));
                        } else {
                          return RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var user = snapshot.data![index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                                  elevation: 5,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                                    title: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        user['name'],
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (user['profile'] != null) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.account_circle, color: Colors.blue, size: 20),
                                              const SizedBox(width: 5),
                                              Text('الباقة: ${user['profile']}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 16,
                                                  )),
                                            ],
                                          ),
                                        ],
                                        if (user['uptime'] != null) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, color: Colors.blue, size: 20),
                                              const SizedBox(width: 5),
                                              Text('الوقت: ${utility.formatDuration(user['uptime'])}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 16,
                                                  )),
                                            ],
                                          ),
                                        ],
                                        if (user['limit-uptime'] != null) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.timer, color: Colors.blue, size: 20),
                                              const SizedBox(width: 5),
                                              Text('الصلاحية : ${utility.formatDuration(user['limit-uptime'] ?? '0s')}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 16,
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showConfirmationDialog(user['.id'], user['name']),
                                    ),
                                  ),
                                );
                              },
                            ),
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
        primarySwatch: Colors.green,
        fontFamily: 'Tajawal',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

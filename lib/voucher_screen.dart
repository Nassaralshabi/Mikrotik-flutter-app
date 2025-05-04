import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'customprint.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';
import 'drawer.dart';
import 'utility/utility.dart';
import 'utility/routerboardservice.dart'; // استيراد خدمة RouterboardService

class VoucherScreen extends StatefulWidget {
  @override
  _VoucherScreenState createState() => _VoucherScreenState();
}

Utility utility = Utility();
RouterboardService routerboardService = RouterboardService();

class _VoucherScreenState extends State<VoucherScreen> {
  late Future<List<dynamic>> hotspotUsers;
  Timer? _timer;
  String? selectedComment;
  List<String> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _loadData());
    _loadComments();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      hotspotUsers = fetchHotspotUsers();
    });
  }

  void _loadComments() async {
    final fetchedComments = await routerboardService.fetchCommentsUnique();
    setState(() {
      comments = fetchedComments;
      isLoading = false;
    });
  }

  Future<List<dynamic>> fetchHotspotUsers() async {
    try {
      final users = await routerboardService.fetchHotspotUsersByComment(selectedComment ?? '');
      return removeDisabledAndExpiredUsers(users);
    } catch (e) {
      throw Exception('Failed to load hotspot users: $e');
    }
  }

  List<dynamic> removeDisabledAndExpiredUsers(List<dynamic> users) {
    return users.where((user) {
      bool isDisabled = user['disabled'] == 'true';
      bool isExpired = user['limit-uptime'] != null &&
          user['limit-uptime'] != '0s' &&
          user['uptime'] != null &&
          user['uptime'] == user['limit-uptime'];
      bool isDefault = user['default'] == 'true';
      return !isDisabled && !isExpired && !isDefault;
    }).toList();
  }

  Future<void> deleteUsersByComment(String comment) async {
    try {
      final users = await routerboardService.fetchHotspotUsersByComment(comment);
      for (var user in users) {
        await routerboardService.deleteUser(user['name']);
      }
      _loadData();
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.success,
        direction: TextDirection.rtl,
        alignment: Alignment.bottomCenter,
        title: const Text('تم حذف الكروت بنجاح'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        direction: TextDirection.rtl,
        alignment: Alignment.bottomCenter,
        title: const Text('حدث خطأ أثناء حذف الكروت'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  Future<bool?> _confirmBulkDelete(BuildContext context, String comment) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف الجماعي'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل أنت متأكد من أنك تريد حذف جميع الكروت لهذه المجموعة؟'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('لا'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('نعم'),
              onPressed: () {
                deleteUsersByComment(comment);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
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
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      locale: const Locale('ar'), // Set default locale to Arabic
      home: Scaffold(
        backgroundColor: Colors.blue[900],
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'الكروت',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue[900],
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => customprint()
                  ),
                  (route) => false,
                );
              },
              iconSize: 30,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: selectedComment == null
                  ? null
                  : () async {
                await _confirmBulkDelete(context, selectedComment!);
              },
              iconSize: 30,
            ),
          ],
        ),
        drawer: MyDrawer(),
        body: Container(
          color: Colors.blue[900],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButton<String>(
                  isDense: true,
                  dropdownColor: Colors.blue[900],
                  value: selectedComment,
                  hint: const Text('اختر المجموعة', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.arrow_downward),
                  iconEnabledColor: Colors.white,
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedComment = newValue!;
                      _loadData(); // Reload data when a new comment is selected
                    });
                  },
                  items: comments.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
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
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<List<dynamic>>(
                      future: hotspotUsers,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('لا توجد بيانات'));
                        } else {
                          return RefreshIndicator(
                            onRefresh: () async {
                              _loadData();
                              await hotspotUsers;
                            },
                            child: ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var user = snapshot.data![index];
                                return Dismissible(
                                  key: Key(user['name']),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await _confirmDelete(context, user['name']);
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                                    elevation: 5,
                                    borderOnForeground: true,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                                      title: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          user['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
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
                                                Text('الوقت المستهلك: ${utility.formatDuration(user['uptime'])}',
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
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String userName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('هل أنت متأكد من أنك تريد حذف هذا الكرت؟'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('لا'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('نعم'),
              onPressed: () {
                deleteUser(userName);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(String userName) async {
    final response = await routerboardService.deleteUser(userName);
    if (response == true) {
      _loadData();
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.success,
        direction: TextDirection.rtl,
        alignment: Alignment.bottomCenter,
        title: const Text('تم حذف الكرت بنجاح'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } else {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        direction: TextDirection.rtl,
        alignment: Alignment.bottomCenter,
        title: const Text('حدث خطأ أثناء حذف الكرت'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../customprint.dart';
import '../utility/routerboardservice.dart';

class ActiveUsers extends StatefulWidget {
  @override
  _ActiveUsersState createState() => _ActiveUsersState();
}

class _ActiveUsersState extends State<ActiveUsers> {
  late Future<List<Map<String, dynamic>>> activeUsers;
  RouterboardService routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    activeUsers = routerboardService.fetchActiveUsers();
  }

  // Refresh the active users list
  Future<void> _refreshActiveUsers() async {
    setState(() {
      activeUsers = routerboardService.fetchActiveUsers();
    });
  }

  // Show delete confirmation dialog
// Show delete confirmation dialog
// Show delete confirmation dialog
  Future<int?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد حذف هذا المستخدم؟',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: Wrap(
                spacing: 10.0,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(0),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(1),
                    child: const Text('حذف من القائمة النشطة'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(2),
                    child: const Text('حذف نهائي'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'المستخدمين النشطين',
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshActiveUsers,
          ),
        ],
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
                  padding: const EdgeInsets.all(20.0),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: activeUsers,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('حدث خطأ أثناء جلب المستخدمين النشطين'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('لا يوجد مستخدمين نشطين حاليًا'));
                      } else {
                        final users = snapshot.data!;
                        return RefreshIndicator(
                          onRefresh: _refreshActiveUsers,
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Dismissible(
                                  key: Key(user['.id']),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) async {
                                    final confirmation = await _showDeleteConfirmation(context);
                                    // customPrint('confirmation: $confirmation');
                                    // 1 => delete from active users list
                                    // 2 => delete from active users list and delete user
                                    // 0 => cancel

                                    if (confirmation == 1) {
                                      await routerboardService.deleteActiveUser(user['.id']);
                                    } else if (confirmation == 2) {
                                      await routerboardService.deleteActiveUser(user['.id']);
                                      await routerboardService.deleteUser(user['user']);
                                      await routerboardService.deleteCookie(user['user']);
                                    }
                                    if (confirmation == 1 || confirmation == 2) {
                                      setState(() {
                                        users.removeAt(index);
                                      });
                                      if(confirmation == 1) {
                                        toastification.show(
                                          context: context,
                                          style: ToastificationStyle.fillColored,
                                          type: ToastificationType.error,
                                          alignment: Alignment.bottomCenter,
                                          direction: TextDirection.rtl,
                                          title: const Text('تم حذف المستخدم من القائمة النشطة'),
                                          autoCloseDuration: const Duration(seconds: 2),
                                        );

                                      } else {
                                        toastification.show(
                                          context: context,
                                          style: ToastificationStyle.fillColored,
                                          type: ToastificationType.error,
                                          alignment: Alignment.bottomCenter,
                                          direction: TextDirection.rtl,
                                          title: const Text('تم حذف المستخدم من القائمة النشطة وحذف المستخدم نهائيًا'),
                                          autoCloseDuration: const Duration(seconds: 2),
                                        );
                                      }
                                    }

                                  },
                                  confirmDismiss: (direction) async {
                                    final confirmation = await _showDeleteConfirmation(context);
                                    return confirmation == 1 || confirmation == 2;
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'حذف',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Tajawal',
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.person, color: Colors.green),
                                              const SizedBox(width: 10),
                                              Text(
                                                'الكرت: ' + user['user'],
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.wifi, color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Text(
                                                'عنوان: ${user['address']}',
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, color: Colors.orange),
                                              const SizedBox(width: 10),
                                              Text(
                                                'مدة النشاط: ${utility.formatDuration(user['uptime'])}',
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.memory, color: Colors.purple),
                                              const SizedBox(width: 10),
                                              Text(
                                                'الماك: ${user['mac-address']}',
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_downward, color: Colors.red),
                                              const SizedBox(width: 10),
                                              Text(
                                                'المستهلك: ${utility.convertKbToMb(user['bytes-in'] + user['bytes-out'])} ميجابايت ',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
    );
  }
}

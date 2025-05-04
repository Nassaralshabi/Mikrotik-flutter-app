import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:toastification/toastification.dart';
import 'utility/utility.dart';
import 'utility/routerboardservice.dart';

class DeviceInfo extends StatefulWidget {
  @override
  _DeviceInfoState createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  late Future<List<Map<String, dynamic>>> combinedData;
  Utility utility = Utility();
  RouterboardService routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    combinedData = Future.wait([
      routerboardService.fetchRouterboardResources(),
      routerboardService.fetchRouterboardInfo()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('معلومات الجهاز',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                combinedData = Future.wait([
                  routerboardService.fetchRouterboardResources(),
                  routerboardService.fetchRouterboardInfo()
                ]);
              });
            },
          )
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
                  child: SingleChildScrollView(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: combinedData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Text('حدث خطأ أثناء جلب موارد الجهاز');
                        } else {
                          final resources = snapshot.data![0];
                          final info = snapshot.data![1];
                          return Column(
                            children: [
                              _buildDetailRow(
                                  'السيريال نمبر', '${info['serial-number']}'),
                              _buildDetailRow('الذاكرة الكلية',
                                  '${utility.convertKbToMb(resources['total-memory'])} ميجابايت'),
                              _buildDetailRow('الذاكرة المتاحة',
                                  '${utility.convertKbToMb(resources['free-memory'])} ميجابايت'),
                              _buildDetailRow('مساحة التخزين الكلية',
                                  '${utility.convertKbToMb(resources['total-hdd-space'])} ميجابايت'),
                              _buildDetailRow('مساحة التخزين المتاحة',
                                  '${utility.convertKbToMb(resources['free-hdd-space'])} ميجابايت'),
                              _buildDetailRow(
                                  'نسخة البرنامج', resources['version']),
                              _buildDetailRow('المعالج', resources['cpu']),
                              _buildDetailRow('تردد المعالج',
                                  '${resources['cpu-frequency']} ميجاهرتز'),
                              _buildDetailRow(
                                  'عدد الأنوية', '${resources['cpu-count']}'),
                              _buildDetailRow(
                                  'اللوحة', resources['board-name']),
                              _buildDetailRow('المنصة', resources['platform']),
                              _buildDetailRow(
                                  'المعمارية', resources['architecture-name']),
                              _buildDetailRow(
                                  'الوقت', resources['build-time']),
                              _buildDetailRow('البرنامج الأساسي',
                                  resources['factory-software']),
                            ],
                          );
                        }
                      },
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

  Widget _buildDetailRow(String label, String value) {
    return GestureDetector(
      onLongPress: () {
        FlutterClipboard.copy(value).then((_) {
          toastification.show(
            context: context,
            style: ToastificationStyle.fillColored,
            type: ToastificationType.success,
            alignment: Alignment.bottomCenter,
            direction: TextDirection.rtl,
            title: const Text('تم النسخ بنجاح'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        });
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'utility/routerboardservice.dart';
import 'printvoucher.dart';
import 'package:toastification/toastification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class VoucherGeneratorScreen extends StatefulWidget {
  @override
  _VoucherGeneratorScreenState createState() => _VoucherGeneratorScreenState();
}

class _VoucherGeneratorScreenState extends State<VoucherGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _timeLimitController = TextEditingController();
  final TextEditingController _dataLimitValueController = TextEditingController();
  String? _selectedTimeLimitUnit;
  String? _selectedValue;
  int _nameLength = 5;
  String? _selectedProfile;
  String? _selectedUserMode;
  String? comment;
  List<String> _profiles = [];
  Map<String, dynamic>? _selectedProfileData;
  List<Map<String, dynamic>> generatedUsers = [];
  final List<Map<String, dynamic>> _userModes = [
    {
      'mode': 'Username & Password',
      'name': 'اسم المستخدم وكلمة المرور'
    },
    {
      'mode': 'Username = Password',
      'name': 'كروت'
    }
  ];

  final List<Map<String, String>> _dataLimitUnits = [
    {'unit': 'G', 'name': 'قيقابايت'},
    {'unit': 'M', 'name': 'ميقابايت'}
  ];
  final Map<String, String> timeLimitUnitsMap = {
    'd': 'يوم',
    'h': 'ساعة',
    'm': 'دقيقة'
  };
  final List<String> _timeLimitUnits = ['d', 'h', 'm'];

  final RouterboardService _routerboardService = RouterboardService();
  bool _isGenerating = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _fetchProfiles();
    _selectedUserMode = _userModes[1]['mode'];
    _selectedTimeLimitUnit = _timeLimitUnits[0];
    _selectedValue = _dataLimitUnits[0]['unit'];
  }

  void _initializeTimeZone() {
    tz.initializeTimeZones();
    final khartoum = tz.getLocation('Africa/Khartoum');
    tz.setLocalLocation(khartoum);
  }

  Future<void> _fetchProfiles() async {
    try {
      final profiles = await _routerboardService.fetchHotspotProfiles();
      setState(() {
        _profiles = profiles.map((profile) => profile['name'] as String).toList();
        _selectedProfile = _profiles.isNotEmpty ? _profiles[0] : null;
        if (_selectedProfile != null) _fetchProfileData(_selectedProfile!);
      });
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('خطأ'),
        description: const Text('فشل في جلب الملفات الشخصية'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _fetchProfileData(String profile) async {
    try {
      final profileData = await _routerboardService.fetchProfileData(profile);
      setState(() {
        _selectedProfileData = profileData;
      });
      print(_selectedProfileData);
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('خطأ'),
        description: const Text('فشل في جلب بيانات الملف الشخصي'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  String _generateRandomString(int length, String characterSet) {
    final random = Random();
    return List.generate(length, (_) => characterSet[random.nextInt(characterSet.length)]).join();
  }

  String _generateBulkId() {
    final random = Random();
    return List.generate(3, (_) => random.nextInt(10)).join();
  }

  Future<void> createVouchers(int quantity) async {
    setState(() {
      _isGenerating = true;
      _progress = 0.0;
    });

    int successCount = 0;
    // get now on khatoum timezone
    final now = tz.TZDateTime.now(tz.getLocation('Africa/Khartoum'));

    String bulkId = _generateBulkId();

    for (int i = 0; i < quantity; i++) {
      String username = _generateRandomString(_nameLength, '1234567890');
      String password = _selectedUserMode == 'Username & Password'
          ? _generateRandomString(_nameLength, '1234567890')
          : username;

      int dataLimitValue = int.parse(_dataLimitValueController.text.isNotEmpty ? _dataLimitValueController.text : '0');
      String prefix = _selectedUserMode == 'Username & Password' ? 'uc' : 'vc';
      String formattedDate = '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}.${now.year.toString().substring(2)}';

      String comment = '$prefix-$bulkId-$formattedDate-';

      final Map<String, dynamic> payload = {
        'name': username,
        'password': password,
        'profile': _selectedProfile,
        'limit-uptime': '${_timeLimitController.text}${_selectedTimeLimitUnit}',
        'limit-bytes-total': _selectedValue == 'M'
            ? dataLimitValue * 1024 * 1024
            : dataLimitValue * 1024 * 1024 * 1024,
        'comment': comment,
      };

      try {
        await _routerboardService.createUser(payload);
        setState(() {
          this.comment = comment;
        });
        successCount++;
      } catch (e) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('خطأ'),
          description: Text('فشل في إنشاء الكرت رقم ${i + 1}'),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }

      setState(() {
        _progress = (i + 1) / quantity;
      });
    }

    setState(() {
      _isGenerating = false;
    });

    if (successCount == quantity) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('نجاح'),
        description: const Text('تم إنشاء جميع الكروت بنجاح'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => PrintVoucher(comment: comment!),),
        (route) => false,
      );
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('خطأ'),
        description: Text('تم إنشاء ${successCount} من أصل ${quantity} كرت بنجاح'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('مولد الكروت الجماعية'),
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'عدد الكروت',
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال عدد الكروت';
                              } else if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'الرجاء إدخال عدد صحيح أكبر من 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            value: _selectedUserMode,
                            decoration: const InputDecoration(
                              labelText: 'نوع الكروت',
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            items: _userModes.map((mode) {
                              return DropdownMenuItem<String>(
                                value: mode['mode'],
                                child: Text(mode['name']),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedUserMode = newValue!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء اختيار وضع المستخدم';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'طول الاسم',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: _nameLength.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label: _nameLength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _nameLength = value.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            value: _selectedProfile,
                            decoration: const InputDecoration(
                              labelText: 'الملف الشخصي',
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            items: _profiles.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedProfile = newValue!;
                                _fetchProfileData(newValue);
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _timeLimitController,
                                  decoration: const InputDecoration(
                                    labelText: 'الحد الزمني',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTimeLimitUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'نوع الحد الزمني',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  items: _timeLimitUnits.map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(timeLimitUnitsMap[unit]!),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedTimeLimitUnit = newValue!;
                                    });
                                  },
                                  validator: (value) {
                                    if (_timeLimitController.text.isNotEmpty && (value == null || value.isEmpty)) {
                                      return 'الرجاء اختيار نوع الحد الزمني';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dataLimitValueController,
                                  decoration: const InputDecoration(
                                    labelText: 'قيمة حد البيانات',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'إختر وحدة حد البيانات',
                                  ),
                                  value: _selectedValue,
                                  items: _dataLimitUnits.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['unit'],
                                      child: Text(item['name']!),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedValue = newValue!;
                                    });
                                  },
                                  validator: (value) {
                                    if (_dataLimitValueController.text.isNotEmpty && (value == null || value.isEmpty)) {
                                      return 'الرجاء اختيار وحدة حد البيانات';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                int quantity = int.parse(_quantityController.text);
                                createVouchers(quantity);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('إنشاء الكروت'),
                          ),
                          const SizedBox(height: 16.0),
                          if (_isGenerating) ...[
                            const Text(
                              'جارٍ إنشاء الكروت...',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            LinearProgressIndicator(value: _progress),
                          ],
                        ],
                      ),
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

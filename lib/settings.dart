// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mikrotik_mndp/listener.dart';
import 'package:mikrotik_mndp/message.dart';
import 'package:mikrotik_mndp/decoder.dart';
import 'package:mikrotik_mndp/product_info_provider.dart';
import 'component/button_design.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dashboard.dart';
import 'utility/routerboardservice.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _networkNameController = TextEditingController();
  final routerboardService = RouterboardService();
  Position? _currentPosition;
  Timer? _mndpTimer;

  final List<MndpMessage> _discoveredDevices = [];
  MndpMessage? _selectedDevice;
  bool _noDevicesFound = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getLocationPermission();
    _fetchDiscoveredDevices();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('mikrotikIp') ?? '';
      _portController.text = prefs.getString('mikrotikPort') ?? '80';
      _usernameController.text = prefs.getString('mikrotikUsername') ?? '';
      _passwordController.text = prefs.getString('mikrotikPassword') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _networkNameController.text = prefs.getString('networkName') ?? '';
    });
  }

  Future<void> _getLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: const Text('المعذرة، يلزم تفعيل إذن الموقع'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _saveSettings() async {
    Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mikrotikIp', _ipController.text);
    await prefs.setString('mikrotikPort', _portController.text);
    await prefs.setString('mikrotikUsername', _usernameController.text);
    await prefs.setString('mikrotikPassword', _passwordController.text);
    await prefs.setString('networkName', _networkNameController.text);

    // check if the user has entered the required fields
    if (_ipController.text.isEmpty ||
        _portController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: const Text('يرجى ملء جميع الحقول'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }
    final data = await routerboardService.checkConnection();
    var message = data['message'];
    if (data['status'] == 'error') {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: Text(message),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    await prefs.setString('mikrotikIp', _ipController.text);
    await prefs.setString('mikrotikPort', _portController.text);
    await prefs.setString('mikrotikUsername', _usernameController.text);
    await prefs.setString('mikrotikPassword', _passwordController.text);
    await prefs.setString('serial-number', data['serial-number']);


    if (data['serial-number'] != null && data['serial-number'] != '') {
      prefs.setString('serial', data['serial-number']);
      var email = prefs.getString('email') ?? '';
      var password = prefs.getString('password') ?? '';

      if (_currentPosition != null) {
        final locationString =
            '${_currentPosition!.latitude},${_currentPosition!.longitude}';
        final response = await routerboardService.saveUserSettings(
          data['serial-number'],
          email,
          password,
          _ipController.text,
          _portController.text,
          _usernameController.text,
          _passwordController.text,
          locationString,
          _networkNameController.text,
        );
        print('Save User Settings Response: ${response.statusCode}');

        if (response.statusCode == 200) {
          toastification.show(
            context: context,
            style: ToastificationStyle.minimal,
            type: ToastificationType.success,
            alignment: Alignment.topCenter,
            direction: TextDirection.rtl,
            title: const Text('تم حفظ الإعدادات بنجاح'),
            autoCloseDuration: const Duration(seconds: 5),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(),
            ),
            (route) => false,
          );
        } else if (response.statusCode == 403) {
          toastification.show(
            context: context,
            style: ToastificationStyle.minimal,
            type: ToastificationType.error,
            alignment: Alignment.topCenter,
            direction: TextDirection.rtl,
            title: const Text('المعذرة لا يمكن الربط مع جهاز Mikrotik مختلف'),
            autoCloseDuration: const Duration(seconds: 10),
          );
          launchUrl(
            Uri.parse('https://wa.me/249912740956?text='
                'تفعيل جهاز جديد : \n'
                'السيريال : ${data['serial-number']} \n'),
          );
        } else if (response.statusCode == 404) {
          toastification.show(
            context: context,
            style: ToastificationStyle.minimal,
            type: ToastificationType.error,
            alignment: Alignment.topCenter,
            direction: TextDirection.rtl,
            title: const Text('المعذرة المستخدم غير موجود'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else {
          toastification.show(
            context: context,
            style: ToastificationStyle.minimal,
            type: ToastificationType.error,
            alignment: Alignment.topCenter,
            direction: TextDirection.rtl,
            title: const Text('المعذرة حدث خطأ في الإتصال'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      } else {
        toastification.show(
          context: context,
          style: ToastificationStyle.minimal,
          type: ToastificationType.error,
          alignment: Alignment.topCenter,
          direction: TextDirection.rtl,
          title: const Text('المعذرة لم يتم الحصول على الموقع الحالي'),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    } else {
      toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.error,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: const Text('المعذرة حدث خطأ في الإتصال'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }

  }

  Future<void> _rebootDevice() async {
    if (await routerboardService.rebootRouter()) {
      toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.info,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: const Text('إعادة تشغيل الجهاز'),
        autoCloseDuration: const Duration(seconds: 50),
      );
    }
  }

  Future<void> _shutdownDevice() async {
    if (await routerboardService.shutdownRouter()) {
      toastification.show(
        context: context,
        style: ToastificationStyle.minimal,
        type: ToastificationType.info,
        alignment: Alignment.topCenter,
        direction: TextDirection.rtl,
        title: const Text('إيقاف تشغيل الجهاز'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }


  Future<void> _fetchDiscoveredDevices() async {
    var productProvider = MikrotikProductInfoProviderImpl();
    var decoder = MndpMessageDecoderImpl(productProvider);
    MNDPListener mndpListener = MNDPListener(decoder);

    mndpListener.listen().listen((message) {
      setState(() {
        var found = false;
        for (var i = 0; i < _discoveredDevices.length; i++) {
          if (_discoveredDevices[i].macAddress == message.macAddress) {
            _discoveredDevices[i] = message;
            found = true;
            break;
          }
        }
        if (!found) {
          _discoveredDevices.add(message);
        }
        _noDevicesFound = _discoveredDevices.isEmpty;
      });
    });

    // Set a timer to stop listening after 10 seconds
    _mndpTimer = Timer(const Duration(seconds: 12), () {
      setState(() {
        _noDevicesFound = _discoveredDevices.isEmpty;
      });
      mndpListener.stop();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _mndpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('الإعدادات'),
        backgroundColor: Colors.blue[900],
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      // drawer: MyDrawer(),
      body: Container(
        color: Colors.blue[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 10),
                        _noDevicesFound
                            ? const Text(
                          'لم يتم إكتشاف اي اجهزة مايكروتك في الشبكة',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                        )
                            : DropdownButton<MndpMessage>(
                          value: _selectedDevice,
                          items: _discoveredDevices.map((device) {
                            return DropdownMenuItem<MndpMessage>(
                              value: device,
                              child: Text(device.identity ?? 'جهاز غير معروف'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDevice = value;
                              _ipController.text = value!.unicastIpv4Address ?? '';
                              _portController.text = '80';
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _networkNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الشبكة',
                          ),
                        ),
                        TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'الأي بي',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'البورت',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ButtonDesign(
                          text: 'حفظ الإعدادات',
                          onPressed: _saveSettings,
                          color: const Color(0xFF0D47A1),
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          iconData: Icons.save,
                        ),
                        const SizedBox(height: 20),

                        ButtonDesign(
                          text: 'إعادة تشغيل الجهاز',
                          onPressed: _rebootDevice,
                          color: Colors.orange,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          iconData: Icons.restart_alt,
                        ),
                        const SizedBox(height: 10),
                        ButtonDesign(
                          text: 'إيقاف تشغيل الجهاز',
                          onPressed: _shutdownDevice,
                          color: Colors.red,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                          iconData: Icons.power_settings_new,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

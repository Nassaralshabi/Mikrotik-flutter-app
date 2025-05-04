// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'plan.dart';
import 'package:toastification/toastification.dart';
import 'component/button_design.dart';
import 'drawer.dart';
import 'utility/routerboardservice.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class NewPlanScreen extends StatefulWidget {
  const NewPlanScreen({super.key});

  @override
  _NewPlanScreenState createState() => _NewPlanScreenState();
}

class _NewPlanScreenState extends State<NewPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? addrpool;
  String? downloadRate;
  String? downloadUnit = 'M'; // Default value
  String? uploadRate;
  String? uploadUnit = 'M'; // Default value
  String? sharedusers = '1'; // Default value is 1
  String? validityValue;
  String? validityUnit = 'd'; // Default value is days
  String? lockUser = 'Disabled';
  String? expmode = 'remove'; // Default value
  List<String> addressPools = [];
  final RouterboardService _routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    fetchAddressPools();
  }

  Future<void> fetchAddressPools() async {
    try {
      final pools = await _routerboardService.fetchAddressPools();
      setState(() {
        addressPools = pools.map((pool) => pool['name'] as String).toList();
      });
    } catch (e) {
      print('Failed to load address pools: $e');
    }
  }

  Future<void> addOrUpdateScheduler(String name, String script) async {

    try {
      tz.initializeTimeZones();
      final khartoum = tz.getLocation('Africa/Khartoum');
      final now = tz.TZDateTime.now(khartoum);
      now.add(const Duration(minutes: 1));

      await _routerboardService.addScheduler({
        "name": name,
        "start-time": 'startup',
        "interval": "30s",
        "on-event": script,
        'comment': 'Monitoring users for profile $name',
      });
    } catch (e) {
      print('Error adding scheduler: $e');
    }
  }

  String generateOnLoginScript(String user, String validity) {
    return '''
    :put (",rem,0,$validity,0,,Disable,"); 
    {:local comment [ /ip hotspot user get [/ip hotspot user find where name="\$user"] comment]; 
    :local ucode [:pick \$comment 0 2]; 
    :if (\$ucode = "vc" or \$ucode = "up" or \$comment = "") do={ 
      :local date [ /system clock get date ];
      :local year [ :pick \$date 7 11 ];
      :local month [ :pick \$date 0 3 ]; 
      /sys sch add name="\$user" disable=no start-date=\$date interval="20s";
      :delay 5s;
      :local exp [ /sys sch get [ /sys sch find where name="\$user" ] next-run];
      :local getxp [len \$exp];
      :if (\$getxp = 15) do={ 
        :local d [:pick \$exp 0 6]; 
        :local t [:pick \$exp 7 16]; 
        :local s ("/"); 
        :local exp ("\$d\$s\$year \$t"); 
        /ip hotspot user set comment="\$exp" [find where name="\$user"];
      };
      :if (\$getxp = 8) do={ 
        /ip hotspot user set comment="\$date \$exp" [find where name="\$user"];
      };
      :if (\$getxp > 15) do={ 
        /ip hotspot user set comment="\$exp" [find where name="\$user"];
      };
      :delay 5s; 
      /sys sch remove [find where name="\$user"]
    }}
  ''';
  }




  String generateBgServiceScript(String profile) {
    return '''
    :local dateint do={
      :local montharray ( "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" );
      :local days [ :pick \$d 4 6 ];
      :local month [ :pick \$d 0 3 ];
      :local year [ :pick \$d 7 11 ];
      :local monthint ([ :find \$montharray \$month]);
      :local month (\$monthint + 1);
      :if ( [len \$month] = 1) do={
        :local zero ("0");
        :return [:tonum ("\$year\$zero\$month\$days")];
      } else={
        :return [:tonum ("\$year\$month\$days")];
      }
    };

    :local timeint do={
      :local hours [ :pick \$t 0 2 ];
      :local minutes [ :pick \$t 3 5 ];
      :return (\$hours * 60 + \$minutes);
    };

    :local date [ /system clock get date ];
    :local time [ /system clock get time ];
    :local today [\$dateint d=\$date];
    :local curtime [\$timeint t=\$time];

    :log info "Current date: \$date";
    :log info "Current time: \$time";
    :log info "Parsed today: \$today";
    :log info "Parsed curtime: \$curtime";

    :foreach i in[/ip hotspot user find where profile="$profile"] do={
      :local comment [ /ip hotspot user get \$i comment];
      :local name [ /ip hotspot user get \$i name];
      :local gettime [ :pick \$comment 12 20 ];
      :log info "Processing user: \$name with comment: \$comment";

      :if ( [:pick \$comment 3] = "/" and [:pick \$comment 6] = "/") do={
        :local expd [ \$dateint d=\$comment ];
        :local expt [ \$timeint t=\$gettime ];
        :log info "Expiration date: \$expd";
        :log info "Expiration time: \$expt";

        :if ( (\$expd < \$today) or (\$expd = \$today and \$expt < \$curtime) ) do={
          :log info "Removing user: \$name";
          [/ip hotspot active remove [find where user=\$name]];
          [/ip hotspot user remove [find where user=\$name]];
          [/ip hotspot cookie remove [find where user=\$name]];
          [/sys sch remove [find where name=\$name]];
          
        }
      }
    }
  ''';
  }




  Future<void> addNewProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    print(validityValue! + validityUnit!);
    final onLoginScript = generateOnLoginScript(
      name!,
      validityValue! + validityUnit!,
    );
    final bgServiceScript = generateBgServiceScript(name!);

    try {
      String rateLimit = "";
      if (uploadRate != null &&
          uploadRate!.isNotEmpty &&
          downloadRate != null &&
          downloadRate!.isNotEmpty) {
        rateLimit = "$uploadRate$uploadUnit/$downloadRate$downloadUnit";
      }

      // Add profile
      await _routerboardService.addProfile({
        "name": name,
        "rate-limit": rateLimit,
        "shared-users": sharedusers,
        "address-pool": addrpool,
        "on-login": onLoginScript,
      });

      // Add or update scheduler if expmode is not 0

      await addOrUpdateScheduler(name!, bgServiceScript);

      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.success,
        alignment: Alignment.bottomCenter,
        direction: TextDirection.rtl,
        title: const Text('تم إضافة الملف الشخصي بنجاح'),
        autoCloseDuration: const Duration(seconds: 2),
      );

      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => PlanScreen())
          , (route) => false);
    } catch (e) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
        direction: TextDirection.rtl,
        title: const Text('حدث خطأ أثناء إضافة الملف الشخصي'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      print('Error adding profile: $e');
    }
  }

  Future<void> deleteProfile(String profileID,String? ProfileID) async {
    try {
      await _routerboardService.deleteProfile(profileID,ProfileID??'');
      await _routerboardService.deleteScheduler(ProfileID??'');

      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.success,
        alignment: Alignment.bottomCenter,
        direction: TextDirection.rtl,
        title: const Text('تم حذف الملف الشخصي بنجاح'),
        autoCloseDuration: const Duration(seconds: 2),
      );

      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => PlanScreen()), (route) => false);
    } catch (e) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        alignment: Alignment.bottomCenter,
        direction: TextDirection.rtl,
        title: const Text('حدث خطأ أثناء حذف الملف الشخصي'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      print('Error deleting profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('إضافة باقة جديدة'),
        backgroundColor: Colors.blue[900],
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              if (name != null) {
                deleteProfile(name!,name??'');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Container(
        color: Colors.blue[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'الاسم'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الاسم';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              name = value;
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                labelText: 'مخزون العناوين'),
                            items: addressPools.map((String pool) {
                              return DropdownMenuItem<String>(
                                value: pool,
                                child: Text(pool),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                addrpool = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء اختيار مخزون العناوين';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'سرعة التحميل'),
                                  keyboardType: TextInputType.number,
                                  onSaved: (value) {
                                    downloadRate = value;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: downloadUnit,
                                items: ['M', 'K'].map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    downloadUnit = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'سرعة الرفع'),
                                  keyboardType: TextInputType.number,
                                  onSaved: (value) {
                                    uploadRate = value;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: uploadUnit,
                                items: ['M', 'K'].map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    uploadUnit = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'عدد المستخدمين المشتركين'),
                            keyboardType: TextInputType.number,
                            initialValue: sharedusers,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال عدد المستخدمين المشتركين';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              sharedusers = value;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'مدة الصلاحية'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال مدة الصلاحية';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    validityValue = value;
                                  },
                                ),
                              ),
                              DropdownButton<String>(
                                value: validityUnit,
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: 'd',
                                    child: Text('يوم'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'h',
                                    child: Text('ساعة'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'm',
                                    child: Text('دقيقة'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    validityUnit = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          ButtonDesign(
                            text: 'إضافة',
                            color: Colors.blue,
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            iconData: Icons.add,
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                addNewProfile();
                              }
                            },
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

import 'package:flutter/material.dart';

typedef ScreenTitleFunction = Widget Function(String title);

class Utility {

  // Format the duration string to a readable string
  String formatDuration(String duration) {
    if(duration == '0s') return 'غير مستخدم';
    int years = 0;
    int months = 0;
    int weeks = 0;
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    // Parse the duration string
    RegExp exp = RegExp(r"((\d+)y)?((\d+)mo)?((\d+)w)?((\d+)d)?((\d+)h)?((\d+)m)?((\d+)s)?");
    Match? match = exp.firstMatch(duration);

    if (match != null) {
      years = int.tryParse(match.group(2) ?? '0') ?? 0;
      months = int.tryParse(match.group(4) ?? '0') ?? 0;
      weeks = int.tryParse(match.group(6) ?? '0') ?? 0;
      days = int.tryParse(match.group(8) ?? '0') ?? 0;
      hours = int.tryParse(match.group(10) ?? '0') ?? 0;
      minutes = int.tryParse(match.group(12) ?? '0') ?? 0;
      seconds = int.tryParse(match.group(14) ?? '0') ?? 0;
    }

    // Build the readable string
    List<String> parts = [];

    if (years > 0) {
      parts.add('$years سنة');
    }
    if (months > 0) {
      parts.add('$months شهر');
    }
    if (weeks > 0) {
      parts.add('$weeks أسبوع');
    }
    if (days > 0) {
      parts.add('$days يوم');
    }
    if (hours > 0) {
      parts.add('$hours ساعة');
    }
    if (minutes > 0) {
      parts.add('$minutes دقيقة');
    }
    if (seconds > 0) {
      parts.add('$seconds ثانية');
    }

    return parts.join(' ');
  }

  // function to convert kilobytes to megabytes
  String convertKbToMb(dynamic kb) {
    if (kb == null) return 'N/A';
    double mb = int.parse(kb) / 1024 / 1024 / 1024;
    return mb.toStringAsFixed(2);
  }

  String convertToHigherUnit(String num) {
    int value = int.parse(num);

    if (value == 0) {
      return "غير مستخدم";
    }

    double convertedValue = value.toDouble();
    String unit = "بايت";

    if (convertedValue >= 1024) {
      convertedValue /= 1024;
      unit = "كيلوبايت";
    }
    if (convertedValue >= 1024) {
      convertedValue /= 1024;
      unit = "ميجابايت";
    }
    if (convertedValue >= 1024) {
      convertedValue /= 1024;
      unit = "جيجابايت";
    }
    if (convertedValue >= 1024) {
      convertedValue /= 1024;
      unit = "تيرابايت";
    }

    return "${convertedValue.toStringAsFixed(0)} $unit";
  }




  // Screen title with custom font
  Widget screenTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontFamily: 'Tajawal',
      ),
    );
  }


  Map<String, dynamic> getTemperatureInfo(double temperature) {
    if (temperature > 80) {
      return {'color': Colors.red, 'message': 'درجة حرارة عالية جداً'};
    } else if (temperature > 60) {
      return {'color': Colors.orange, 'message': 'درجة حرارة عالية'};
    } else if (temperature > 40) {
      return {'color': Colors.orangeAccent, 'message': 'درجة حرارة متوسطة'};
    } else if (temperature > 20) {
      return {'color': Colors.green, 'message': 'درجة حرارة باردة'};
    } else {
      return {'color': Colors.blue, 'message': 'درجة حرارة باردة جداًً'};
    }
  }

  String convertSpeedRate(String speedRate) {
    // نقسم النص إلى سرعة التحميل والرفع باستخدام الفاصلة المائلة "/"
    List<String> speeds = speedRate.split('/');

    // تحويل كل جزء إلى نص قابل للقراءة الإنسانية
    String downloadSpeed = _convertSpeed(speeds[0]);
    String uploadSpeed = _convertSpeed(speeds[1]);

    // if the download and upload speeds are the same, return one speed

    return 'سرعة التحميل : $downloadSpeed\nسرعة الرفع : $uploadSpeed';
  }

  String _convertSpeed(String speed) {
    // فحص وحدة القياس (k أو m)
    if (speed.endsWith('k')) {
      return '${speed.replaceAll('k', '')} كيلو بايت';
    } else if (speed.endsWith('m')) {
      return '${speed.replaceAll('m', '')} ميقابايت';
    } else {
      return speed; // في حالة عدم وجود وحدة قياس معروفة
    }
  }


}
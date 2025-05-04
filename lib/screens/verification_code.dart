import 'dart:async';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../activation_request.dart';
import '../component/button_design.dart';
import '../utility/routerboardservice.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;

  VerificationCodeScreen({required this.email});

  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final RouterboardService _routerboardService = RouterboardService();
  String _otpData = "";
  final formKey = GlobalKey<FormState>();
  TextEditingController textEditingController = TextEditingController();
  StreamController<ErrorAnimationType>? errorController;

  @override
  void initState() {
    errorController = StreamController<ErrorAnimationType>();
    super.initState();
  }

  @override
  void dispose() {
    errorController!.close();
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _otpData = textEditingController.text;
    });

    try {
      final response = await _routerboardService.verifyOtp(widget.email, _otpData);

      if (response['status_code'] == 200) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.success,
          direction: TextDirection.rtl,
          title: const Text('تم التحقق بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivationRequest(),
          ),
          (route) => false,
        );
      } else if (response['status_code'] == 401) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: const Text('خطأ في رمز التحقق'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else if (response['status_code'] == 404) {
        toastification.show(
          context: context,
          style: ToastificationStyle.fillColored,
          type: ToastificationType.error,
          direction: TextDirection.rtl,
          title: const Text('المستخدم غير موجود'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        style: ToastificationStyle.fillColored,
        type: ToastificationType.error,
        direction: TextDirection.rtl,
        title: Text('خطأ: $e'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }

    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلب رمز التحقق',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1), // Dark blue background color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF0D47A1), // Dark blue background color
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 60), // Space after the logo
                Container(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      const Text(
                        'إدخال رمز التحقق',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1), // Dark blue text color
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'تم إرسال رمز التحقق إلى البريد الإلكتروني الخاص بك',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Form(
                        key: formKey,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 30,
                          ),
                          child: PinCodeTextField(
                            appContext: context,
                            pastedTextStyle: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                            length: 4,
                            obscureText: true,
                            blinkWhenObscuring: true,
                            animationType: AnimationType.fade,
                            autoFocus: true,
                            onCompleted: (v) {
                             _verifyOtp();
                            },
                            validator: (v) {
                              if (v!.length < 4) {
                                return "من فضلك أدخل الرمز بالكامل";
                              } else {
                                return null;
                              }
                            },
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(20),
                              fieldHeight: 50,
                              fieldWidth: 50,
                              activeFillColor: Colors.white,
                            ),
                            cursorColor: Colors.black,
                            animationDuration: const Duration(milliseconds: 300),
                            enableActiveFill: false,
                            errorAnimationController: errorController,
                            controller: textEditingController,
                            keyboardType: TextInputType.number,
                            boxShadows: const [
                              BoxShadow(
                                offset: Offset(0, 1),
                                color: Colors.black12,
                                blurRadius: 10,
                              )
                            ],
                            onChanged: (value) {
                              debugPrint(value);
                              setState(() {
                                _otpData = value;
                              });
                            },
                            errorTextDirection: TextDirection.rtl,

                            beforeTextPaste: (text) {
                              debugPrint("Allowing to paste $text");
                              return true;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ButtonDesign(
                        text: 'تحقق',
                        onPressed: _verifyOtp,
                        color: Colors.green,
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        iconData: Icons.check,
                      ),
                      const SizedBox(height: 40),
                    ],
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

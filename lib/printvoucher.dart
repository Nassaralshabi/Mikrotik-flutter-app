import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer.dart';
import 'utility/utility.dart';
import 'utility/routerboardservice.dart';

class PrintVoucher extends StatefulWidget {
  final String comment;

  const PrintVoucher({super.key, required this.comment});

  @override
  _PrintVoucherState createState() => _PrintVoucherState();
}

class _PrintVoucherState extends State<PrintVoucher> {
  Utility utility = Utility();
  RouterboardService routerboardService = RouterboardService();
  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rawData = await routerboardService.fetchUsersByComment(widget.comment);
      final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(rawData['users'] ?? []);

      setState(() {
        this.users = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _printVouchers(List<dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    final networkName = prefs.getString('networkName');

    final pdf = pw.Document();
    final arabicFont = await rootBundle.load("assets/fonts/Tajawal-Medium.ttf");
    final ttf = pw.Font.ttf(arabicFont);

    const int cardsPerRow = 5;
    const int rowsPerPage = 10;

    List<pw.Widget> createVoucherWidgets(List<dynamic> users) {
      List<pw.Widget> rows = [];
      for (int i = 0; i < users.length; i += cardsPerRow) {
        List<pw.Widget> row = [];
        for (int j = 0; j < cardsPerRow; j++) {
          if (i + j < users.length) {
            var user = users[i + j];
            row.add(
              pw.Container(
                width: (PdfPageFormat.a4.width - (cardsPerRow + 1) * 10) /
                    cardsPerRow,
                height: (PdfPageFormat.a4.height - (rowsPerPage + 3)) / rowsPerPage,
                margin: const pw.EdgeInsets.only(
                  bottom: 5,
                  left: 5,
                  right: 5,
                ),
                padding: const pw.EdgeInsets.all(1),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Text(
                          '${i + j + 1}',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.Text(
                          networkName ?? '',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '${user['name'] ?? ''}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 23,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${user['profile'] ?? ''}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            utility.formatDuration(user['limit-uptime'] ?? '0s'),
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else {
            row.add(pw.Container(
              width: (PdfPageFormat.a4.width - (cardsPerRow + 1) * 10) /
                  cardsPerRow,
              margin: const pw.EdgeInsets.all(5),
            ));
          }
        }
        rows.add(pw.Row(children: row));
      }
      return rows;
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.only(
          top: 5,
          bottom: 5,
          left: 5,
          right: 5,
        ),
        build: (pw.Context context) {
          return createVoucherWidgets(users);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _printThermalVouchers() async {
    final pdf = pw.Document();
    final arabicFont = await rootBundle.load("assets/fonts/Tajawal-Medium.ttf");
    final ttf = pw.Font.ttf(arabicFont);

    for (var user in users) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Container(
              width: PdfPageFormat.roll80.width,
              margin: const pw.EdgeInsets.all(5),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(
                      '${user['name'] ?? ''}',
                      style: pw.TextStyle(
                          font: ttf,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  if (user['profile'] != null)
                    pw.Text(
                      'الباقة: ${user['profile'] ?? ''}',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                  if (user['limit-uptime'] != null)
                    pw.Text(
                      'الصلاحية: ${utility.formatDuration(user['limit-uptime'] ?? '0s')}',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: ttf, fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'), // Arabic
        Locale('en', 'US'), // English
      ],
      locale: const Locale('ar'),
      home: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'طباعة الكروت المولدة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue[900],
        ),
        drawer: MyDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
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
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var user = users[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          margin: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 5.0),
                          elevation: 5,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            title: Align(
                              alignment: Alignment.center,
                              child: Text(
                                user['name'] ?? '',
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
                                      const Icon(Icons.account_circle,
                                          color: Colors.blue, size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        'الباقة: ${user['profile'] ?? ''}',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (user['uptime'] != null) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: Colors.blue, size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        'الوقت المستهلك: ${utility.formatDuration(user['uptime'] ?? '0s')}',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (user['limit-uptime'] != null) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer,
                                          color: Colors.blue, size: 20),
                                      const SizedBox(width: 5),
                                      Text(
                                        'الصلاحية : ${utility.formatDuration(user['limit-uptime'] ?? '0s')}',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double buttonWidth = (constraints.maxWidth - 32) / 2;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _printVouchers(users),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            minimumSize: Size(buttonWidth, 40),
                          ),
                          child: const Text(
                            'طباعة A4',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _printThermalVouchers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            minimumSize: Size(buttonWidth, 40),
                          ),
                          child: const Text(
                            'طباعة كاشير',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdf/pdf.dart';
import 'dart:async';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'utility/utility.dart';
import 'drawer.dart';
import 'utility/routerboardservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class customprint extends StatefulWidget {
  @override
  _customprintState createState() => _customprintState();
}

Utility utility = Utility();

class _customprintState extends State<customprint> {
  List<String> comments = [];
  String? selectedComment;
  bool isLoading = true;
  late Future<List<dynamic>> hotspotUsers;
  final routerboardService = RouterboardService();

  @override
  void initState() {
    super.initState();
    routerboardService.fetchCommentsUnique().then((value) {
      setState(() {
        comments = value;
        isLoading = false;
      });
    });
  }

  void _printThermalVouchers(List<dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    final networkName = prefs.getString('networkName');

    final pdf = pw.Document();
    final arabicFont = await rootBundle.load("assets/fonts/Tajawal-Medium.ttf");
    final ttf = pw.Font.ttf(arabicFont);

    for (var i = 0; i < users.length; i++) {
      var user = users[i];
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: ttf),
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
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'رقم الكرت : ${i + 1}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
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
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'رقم الكرت',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '${user['name'] ?? ''}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'أسم الباقة',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${user['profile'] ?? ''}',
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'الصلاحية',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          utility.formatDuration(user['limit-uptime'] ?? '0s'),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'الكمية',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${utility.convertToHigherUnit(user['limit-bytes-total'] ?? '')} ',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
          backgroundColor: Colors.blue[900],
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
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              DropdownButton<String>(
                                value: selectedComment,
                                hint: const Text('اختر المجموعة'),
                                items: comments.map((String comment) {
                                  return DropdownMenuItem<String>(
                                    value: comment,
                                    child: Text(comment),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedComment = newValue;
                                  });
                                },
                              ),
                              Expanded(
                                child: selectedComment == null
                                    ? const Center(
                                        child: Text(
                                            'اختر التعليق لعرض المستخدمين'))
                                    : FutureBuilder<List<dynamic>>(
                                        future: routerboardService
                                            .fetchHotspotUsersByComment(
                                                selectedComment!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'Error: ${snapshot.error}'));
                                          } else if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return const Center(
                                                child: Text('لا توجد بيانات'));
                                          } else {
                                            return ListView.builder(
                                              itemCount: snapshot.data!.length,
                                              itemBuilder: (context, index) {
                                                var user =
                                                    snapshot.data![index];
                                                return Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0),
                                                  ),
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10.0,
                                                      horizontal: 5.0),
                                                  elevation: 5,
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            vertical: 10.0,
                                                            horizontal: 15.0),
                                                    title: Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        user['name'],
                                                        style: const TextStyle(
                                                          fontSize: 18.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (user['profile'] !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .account_circle,
                                                                  color: Colors
                                                                      .blue,
                                                                  size: 15),
                                                              const SizedBox(
                                                                  width: 5),
                                                              Text(
                                                                  'الباقة: ${user['profile']}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'Tajawal',
                                                                    fontSize:
                                                                        14,
                                                                  )),
                                                            ],
                                                          ),
                                                        ],
                                                        if (user['uptime'] !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .access_time,
                                                                  color: Colors
                                                                      .blue,
                                                                  size: 20),
                                                              const SizedBox(
                                                                  width: 5),
                                                              Text(
                                                                  'الوقت: ${utility.formatDuration(user['uptime'])}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'Tajawal',
                                                                    fontSize:
                                                                        14,
                                                                  )),
                                                            ],
                                                          ),
                                                        ],
                                                        if (user[
                                                                'limit-uptime'] !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons.timer,
                                                                  color: Colors
                                                                      .blue,
                                                                  size: 20),
                                                              const SizedBox(
                                                                  width: 5),
                                                              Text(
                                                                  'الصلاحية : ${utility.formatDuration(user['limit-uptime'] ?? '0s')}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontFamily:
                                                                        'Tajawal',
                                                                    fontSize:
                                                                        14,
                                                                  )),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        },
                                      ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double buttonWidth = (constraints.maxWidth - 48) / 2; // Adjust the value according to the padding

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: selectedComment == null
                              ? null
                              : () async {
                            List<dynamic> users = await routerboardService
                                .fetchHotspotUsersByComment(selectedComment!);
                            _printVouchers(users);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            minimumSize: Size(buttonWidth, 40),
                          ),
                          child: const Text(
                            'طباعة الكروت A4',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedComment == null
                              ? null
                              : () async {
                            List<dynamic> users = await routerboardService
                                .fetchHotspotUsersByComment(selectedComment!);
                            _printThermalVouchers(users);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            minimumSize: Size(buttonWidth, 40),
                          ),
                          child: const Text(
                            'طباعة الكروت POS',
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

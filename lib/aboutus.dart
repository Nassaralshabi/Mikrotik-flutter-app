import 'package:flutter/material.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({Key? key}) : super(key: key);

  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        title: const Text('من نحن',
            style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        backgroundColor: const Color(0xFF0D47A1), // لون الخلفية الأزرق الداكن
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'من نحن',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(),
                const SizedBox(height: 20),
                const Text(
                  'نحن شركة متخصصة في تقديم حلول تقنية متكاملة، هدفنا هو تلبية احتياجات عملائنا بأعلى جودة وأفضل خدمة. نقدم مجموعة واسعة من الخدمات تشمل تطوير البرمجيات، تصميم المواقع والتطبيقات، وتحليل البيانات.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'رؤيتنا',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'أن نكون الرواد في مجال التقنية، وأن نقدم حلول مبتكرة تساعد عملائنا على تحقيق أهدافهم وتطوير أعمالهم.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'قيمنا',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'الاحترافية، الابتكار، النزاهة، والتفاني في العمل هي القيم التي نؤمن بها ونعمل بها في كل مشروع نقوم به.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'تواصل معنا',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'البريد الإلكتروني: info@nassar-tech.com',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'الهاتف: 773114243',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'المطور: Eng: Nassar Alshabi',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
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

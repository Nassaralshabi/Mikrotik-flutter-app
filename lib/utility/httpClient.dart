import 'package:http/http.dart' as http;

class Httpclient{
  // get request
  Future<dynamic> get(String url, Map<String, String> headers) async {
    var response = await http.get(Uri.parse(url), headers: headers);
    return response;
  }

  // post request
  Future<dynamic> post(String url, Map<String, String> headers, dynamic body) async {
    var response = await http.post(Uri.parse(url), headers: headers, body: body);
    return response;
  }

  // put request
  Future<dynamic> put(String url, Map<String, String> headers, dynamic body) async {
    var response = await http.put(Uri.parse(url), headers: headers, body: body);
    return response;
  }

  // delete request
  Future<dynamic> delete(String url, Map<String, String> headers) async {
    var response = await http.delete(Uri.parse(url), headers: headers);
    return response;
  }

}
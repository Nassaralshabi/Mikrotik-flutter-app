import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RouterboardService {
  String _baseUrl = '';
  String _authHeader = '';


  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    tz.initializeTimeZones();
    tz.getLocation('Africa/Khartoum');
    final ip = prefs.getString('mikrotikIp') ?? 'default_ip';
    final port = prefs.getString('mikrotikPort') ?? 'default_port';
    final username = prefs.getString('mikrotikUsername') ?? 'default_username';
    final password = prefs.getString('mikrotikPassword') ?? 'default_password';
    _baseUrl = 'http://$ip:$port/rest';
    _authHeader = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
  }

  Future<Map<String, dynamic>> registerUser(Map<String, String> userData) async {
    final response = await http.post(
      Uri.parse('https://aywa.sd/api/register'),
      body: userData,
    );
    try {
      return json.decode(response.body);
    } catch (e) {
      // If the response is not JSON, return a generic error
      return {
        'status': 'error',
        'message': 'خطأ في الاتصال بالخادم',
        'status_code': response.statusCode,
      };
    }
  }

  Future<Map<String, dynamic>> fetchRouterboardInfo() async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/system/routerboard'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load routerboard info');
    }
  }

  Future<List<dynamic>> fetchAddressPools() async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/pool'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load address pools');
    }
  }

  Future<void> addProfile(Map<String, dynamic> payload) async {
    await _loadConfig();
    final response = await http.post(
      Uri.parse('$_baseUrl/ip/hotspot/user/profile/add'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add profile');
    }
  }

  Future<List<dynamic>> fetchHotspotProfiles() async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user/profile'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hotspot profiles');
    }
  }

  Future<bool> deleteProfile(String profileID, String profileName) async {
    await _loadConfig();
    final response = await http.delete(
      Uri.parse('$_baseUrl/ip/hotspot/user/profile/$profileID'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    // delete scheduler if it exists
    if (response.statusCode == 204) {
      // delete scheduler if it exists
      final scheduler = await findSchedulerByName(profileName);
      if (scheduler.isNotEmpty) {
        await deleteScheduler(profileName);
      }
      return true;
    } else {
      return false;
    }
  }

  Future<void> updateUserComment(String userName, String newComment) async {
    await _loadConfig();
    final response = await http.put(
      Uri.parse('$_baseUrl/ip/hotspot/user/$userName'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
      body: jsonEncode({
        "comment": newComment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user comment');
    }
  }

  Future<List<dynamic>> fetchExpiredUsers() async {
    await _loadConfig();

    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      final List<dynamic> expiredUsers = [];
      for (var user in users) {
        final userUptime = user['uptime'];
        final userLimitUptime = user['limit-uptime'];
        //
        // if user time limit is reached add user to expired users list
        if (userUptime != '0s' && userLimitUptime != '0s') {
          expiredUsers.add(user);
        }
      }
      return expiredUsers;
    } else {
      throw Exception('Failed to load expired users');
    }
  }

  Future<void> deleteScheduler(String profileName) async {
    await _loadConfig();
    final response = await http.delete(
      Uri.parse('$_baseUrl/system/scheduler/$profileName'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete scheduler');
    }
  }

  Future<void> deleteActiveUser(String userId) async {
    await _loadConfig();
    final response = await http.delete(
      Uri.parse('$_baseUrl/ip/hotspot/active/$userId'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> deleteAllExpiredUsers(List<dynamic> expiredUsers) async {
    await _loadConfig();
    try {
      for (var user in expiredUsers) {
        await deleteVoucher(user['.id']);
      }
    } catch (e) {
      throw Exception('Error deleting all expired users: $e');
    }
  }

  Future<List<dynamic>> fetchUsersByIds(List<String> ids) async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      final List<dynamic> usersByIds = [];
      for (var user in users) {
        if (ids.contains(user['.id'])) {
          usersByIds.add(user);
        }
      }
      return usersByIds;
    } else {
      throw Exception('Failed to load users by ids');
    }
  }

  Future<Map<String, dynamic>> fetchUsersByComment(String comment) async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        return {
          'users': users.where((user) => user['comment'] == comment).toList(),
        };
      } else {
        throw Exception('Failed to load routerboard users by comment');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard users by comment: $e');
    }
  }

  Future<List<String>> fetchCommentsUnique() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final List<String> comments = [];
        for (var user in users) {
          if (user['comment'] != null &&
              user['comment'] != '' &&
              user['name'] != 'default-trial') {
            comments.add(user['comment']);
          }
        }
        return comments.toSet().toList();
      } else {
        throw Exception('Failed to load routerboard users comments');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard users comments: $e');
    }
  }

  Future<Map<String, dynamic>> checkConnection() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/routerboard'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check connection');
      }
    } catch (e) {
      throw Exception('Error checking connection: $e');
    }


  }


  Future<void> updateProfile(
      String profileName, Map<String, dynamic> payload) async {
    await _loadConfig();
    final response = await http.put(
      Uri.parse('$_baseUrl/ip/hotspot/user/profile/$profileName'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<http.Response> saveUserSettings(
      String serialNumber,
      String email,
      String password,
      String mikrotikIp,
      String mikrotikPort,
      String mikrotikUsername,
      String mikrotikPassword,
      String location,
      String networkName,
      ) async {
    final response = await http.post(
      Uri.parse('https://aywa.sd/api/update'),
      headers: {
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
      body: json.encode({
        'serialNumber': serialNumber,
        'email': email,
        'password': password,
        'mikrotikIp': mikrotikIp,
        'mikrotikPort': mikrotikPort,
        'mikrotikUsername': mikrotikUsername,
        'mikrotikPassword': mikrotikPassword,
        'location': location,
        'networkName': networkName,
      }),
    );
    return response;
  }

  Future<Map<String, dynamic>> fetchRouterboardResources() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/resource'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routerboard resources');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard resources: $e');
    }
  }

  Future<String> getActiveUsersCount() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/active'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        return users.length.toString();
      } else {
        throw Exception('Failed to load routerboard active users count');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard active users count: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveUsers() async {
    await _loadConfig();
    final response =
    await http.get(Uri.parse('$_baseUrl/ip/hotspot/active'), headers: {
      'Authorization': _authHeader,
      'Content-Type': 'application/json',
      'Charset': 'utf-8',
    });

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load active users');
    }
  }

  Future<List<dynamic>> fetchHotspotUsers() async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> users = json.decode(response.body);
      users = users
          .where((user) =>
      user['uptime'] == "0s" &&
          user['comment'] != "counters and limits for trial users" &&
          user['comment'].toString().isNotEmpty)
          .toList();
      return users;
    } else {
      throw Exception('Failed to load hotspot users');
    }
  }

  Future<List<dynamic>> fetchHotspotUsersByComment(String comment) async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user?comment=$comment'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> users = json.decode(response.body);
      users = users
          .where((user) =>
      user['comment'] != null &&
          user['comment'] == comment &&
          user['uptime'] == "0s" &&
          user['comment'] != "counters and limits for trial users" &&
          user['comment'].toString().isNotEmpty)
          .toList();
      return users;
    } else {
      throw Exception('Failed to load hotspot users');
    }
  }

 Future<Map<String, dynamic>> login(String email, String password) async {
  final headers = {
    'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
  };

  final body = 'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}';

  try {
    final response = await http.post(
      Uri.parse('https://aywa.sd/api/login'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      return {
        'status': 'error',
        'message': 'فشل الاتصال بالخادم (${response.statusCode})',
        'status_code': response.statusCode,
      };
    }

    final parsed = json.decode(response.body);

    if (parsed['status'] == 'success') {
      return parsed;
    } else {
      return {
        'status': 'error',
        'message': parsed['message'] ?? 'حدث خطأ غير متوقع',
        'status_code': response.statusCode,
      };
    }
  } catch (e) {
    return {
      'status': 'error',
      'message': 'خطأ في الاتصال بالخادم: $e',
      'status_code': 500,
    };
  }
}

  Future<bool> deleteUser(String userName) async {
    await _loadConfig();
    final response = await http.delete(
      Uri.parse('$_baseUrl/ip/hotspot/user/$userName'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchProfileData(String profileName) async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/ip/hotspot/user/profile/$profileName'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile data');
    }
  }

  Future<Map<String, dynamic>> systemHealth() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/health'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routerboard health');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard health: $e');
    }
  }

  Future<Map<String, dynamic>> users() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routerboard users');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard users: $e');
    }
  }

  Future<Map<String, dynamic>> profiles() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user/profile'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routerboard profiles');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard profiles: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUsersByProfile(String profile) async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user?profile=$profile'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load routerboard users by profile');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard users by profile: $e');
    }
  }

  Future<int> getUsersCount() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        return users.length;
      } else {
        throw Exception('Failed to load routerboard users count');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard users count: $e');
    }
  }

  Future<List<String>> getUserProfiles() async {
    await _loadConfig();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        return users.map<String>((user) => user['profile'].toString()).toList();
      } else {
        throw Exception('Failed to load routerboard user profiles');
      }
    } catch (e) {
      throw Exception('Error fetching routerboard user profiles: $e');
    }
  }

  Future<Map<String, int>> fetchUserProfilesAndUsers() async {
    await _loadConfig();
    try {
      final profilesResponse = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user/profile'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );
      final usersResponse = await http.get(
        Uri.parse('$_baseUrl/ip/hotspot/user'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
      );

      if (profilesResponse.statusCode == 200 &&
          usersResponse.statusCode == 200) {
        final profiles = json.decode(profilesResponse.body) as List;
        final users = json.decode(usersResponse.body) as List;
        return {
          'profilesCount': profiles.length,
          'usersCount': users.length,
        };
      } else {
        throw Exception('Failed to load user profiles and users');
      }
    } catch (e) {
      throw Exception('Error fetching user profiles and users: $e');
    }
  }

  Future<void> sendSerialNumber(String serialNumber, String email) async {
    await _loadConfig();

    final url = Uri.parse('https://aywa.sd/api/update');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'serialNumber': serialNumber,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return;
      } else {
        throw Exception('Failed to send serial number: ${data['message']}');
      }
    } else {
      throw Exception('Failed to send serial number: ${response.reasonPhrase}');
    }
  }

  Future<bool> checkUsername(String name) async {
    await _loadConfig();
    final url = Uri.parse('$_baseUrl/ip/hotspot/user?name=$name');
    final response = await http.get(url, headers: {
      'Authorization': _authHeader,
      'Content-Type': 'application/json',
      'Charset': 'utf-8',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data.isNotEmpty;
    } else {
      throw Exception('Failed to check username');
    }
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    await _loadConfig();
    final url = Uri.parse('$_baseUrl/ip/hotspot/user/add');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
          'Charset': 'utf-8',
        },
        body: json.encode(payload),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<bool> deleteVoucher(String user) async {
    await _loadConfig();
    final response = await http.delete(
      Uri.parse('$_baseUrl/ip/hotspot/user/$user'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> deleteCookie(String username) async {
    await _loadConfig();
    final id = await getUserCookieId(username);
    final response = await http.delete(
      Uri.parse('$_baseUrl/ip/hotspot/cookie/$id'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> getUserCookieId(String username) async {
    await _loadConfig();
    final url = Uri.parse('$_baseUrl/ip/hotspot/cookie?user=$username');
    final response = await http.get(url, headers: {
      'Authorization': _authHeader,
      'Content-Type': 'application/json',
      'Charset': 'utf-8',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isEmpty) {
        return '';
      } else {
        return data[0]['.id'];
      }
    } else {
      throw Exception('Failed to get user cookie ID');
    }
  }

  Future<List<dynamic>> fetchSchedulers() async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/system/scheduler'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load schedulers');
    }
  }

  Future<void> addScheduler(Map<String, dynamic> payload) async {
    await _loadConfig();
    final response = await http.post(
      Uri.parse('$_baseUrl/system/scheduler/add'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add scheduler');
    }
  }

  Future<Map<String, dynamic>> findSchedulerByName(String name) async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/system/scheduler?name=$name'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      final schedulers = json.decode(response.body);
      return schedulers.isNotEmpty ? schedulers[0] : {};
    } else {
      throw Exception('Failed to find scheduler by name');
    }
  }

  Future<bool> rebootRouter() async {
    await _loadConfig();
    final response = await http.post(
      Uri.parse('$_baseUrl/system/reboot'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> shutdownRouter() async {
    await _loadConfig();
    final response = await http.post(
      Uri.parse('$_baseUrl/system/shutdown'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> backupRouter() async {
    await _loadConfig();
    // Backup functionality is missing; returning true for now
    return true;
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('https://aywa.sd/api/verifyOtp'),
      body: {'email': email, 'otp': otp},
    );
      return json.decode(response.body);
  }


  Future<String> fetchSchedulerIdByName(String name) async {
    await _loadConfig();
    final response = await http.get(
      Uri.parse('$_baseUrl/system/scheduler?name=$name'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
        'Charset': 'utf-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> schedulers = json.decode(response.body);
      if (schedulers.isNotEmpty) {
        return schedulers[0]['.id'];
      } else {
        return '';
      }
    } else {
      throw Exception('Failed to load scheduler id by name');
    }
  }
}

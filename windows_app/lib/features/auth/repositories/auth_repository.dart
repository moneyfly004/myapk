import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../../../core/utils/logger.dart';

class AuthRepository {
  static const String _baseUrl = 'https://dy.moneyfly.top';
  static const String _apiBase = '$_baseUrl/api/v1';
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _usernameKey = 'auth_username';
  static const String _subscriptionUrlKey = 'subscription_url';
  static const String _expireTimeKey = 'expire_time';
  static const String _hasSubscriptionKey = 'has_subscription';
  static const String _maxDevicesKey = 'max_devices';
  static const String _onlineDevicesKey = 'online_devices';

  final http.Client _client = http.Client();

  // 获取保存的 token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 保存 token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 保存用户信息
  Future<void> saveUserInfo(String email, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
  }

  // 获取用户信息
  Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
    };
  }

  // 检查是否已登录
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // 登录
  Future<Result<LoginResponse>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      Logger.debug('登录请求: $_apiBase/auth/login');
      Logger.debug('登录响应码: ${response.statusCode}');
      Logger.debug('登录响应体: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final loginResponse = LoginResponse.fromJson(json);
          await saveToken(loginResponse.token);
          await saveUserInfo(loginResponse.email, loginResponse.username);
          Logger.debug('登录成功: ${loginResponse.email}');
          return Result.success(loginResponse);
        } else {
          final message = json['message'] as String? ?? '登录失败';
          Logger.error('登录失败: $message');
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        Logger.error('登录请求失败: ${response.statusCode}, 错误: $errorMessage');
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('登录异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 注册
  Future<Result<String>> register(
    String username,
    String email,
    String password, {
    String? verificationCode,
    String? inviteCode,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiBase/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          if (verificationCode != null) 'verification_code': verificationCode,
          if (inviteCode != null) 'invite_code': inviteCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final message = json['message'] as String? ?? '注册成功';
          Logger.debug('注册成功: $email');
          return Result.success(message);
        } else {
          final message = json['message'] as String? ?? '注册失败';
          Logger.error('注册失败: $message');
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        Logger.error('注册请求失败: ${response.statusCode}, 错误: $errorMessage');
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('注册异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 发送验证码
  Future<Result<String>> sendVerificationCode(
    String email,
    String type,
  ) async {
    try {
      final token = await getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.post(
        Uri.parse('$_apiBase/auth/send-verification-code'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'type': type, // 'register' or 'reset_password'
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final message = json['message'] as String? ?? '验证码已发送';
          return Result.success(message);
        } else {
          final message = json['message'] as String? ?? '发送失败';
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('发送验证码异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 忘记密码
  Future<Result<String>> forgotPassword(
    String email,
    String verificationCode,
    String newPassword,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$_apiBase/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verification_code': verificationCode,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final message = json['message'] as String? ?? '密码重置成功';
          return Result.success(message);
        } else {
          final message = json['message'] as String? ?? '密码重置失败';
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('忘记密码异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 获取用户订阅信息
  Future<Result<UserSubscription>> getUserSubscription() async {
    try {
      final token = await getToken();
      if (token == null) {
        return Result.failure(Exception('未登录'));
      }

      final response = await _client.get(
        Uri.parse('$_apiBase/user/subscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['data'] as Map<String, dynamic>;
          final subscription = UserSubscription.fromJson(data);

          // 保存订阅信息
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_subscriptionUrlKey, subscription.universalUrl);
          await prefs.setString(_expireTimeKey, subscription.expireTime);
          await prefs.setInt(_maxDevicesKey, subscription.maxDevices);
          await prefs.setInt(_onlineDevicesKey, subscription.onlineDevices);
          await prefs.setBool(_hasSubscriptionKey, true);

          return Result.success(subscription);
        } else {
          final message = json['message'] as String? ?? '获取订阅信息失败';
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('获取订阅信息异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_subscriptionUrlKey);
    await prefs.remove(_expireTimeKey);
    await prefs.remove(_hasSubscriptionKey);
    await prefs.remove(_maxDevicesKey);
    await prefs.remove(_onlineDevicesKey);
  }

  // 获取订阅 URL
  Future<String?> getSubscriptionUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionUrlKey);
  }

  // 获取到期时间
  Future<String?> getExpireTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expireTimeKey);
  }

  // 获取最大设备数
  Future<int> getMaxDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxDevicesKey) ?? 0;
  }

  // 获取在线设备数
  Future<int> getOnlineDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_onlineDevicesKey) ?? 0;
  }

  // 解析错误消息
  String _parseErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? '请求失败，请检查网络连接';
    } catch (e) {
      return '请求失败，请检查网络连接';
    }
  }

  // 获取错误消息
  String _getErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('timeout')) {
      return '连接超时，请检查网络连接';
    } else if (message.contains('SSL') || message.contains('Certificate')) {
      return 'SSL 连接错误，请检查网络设置';
    } else if (message.contains('Failed host lookup') ||
        message.contains('SocketException')) {
      return '无法连接到服务器，请检查网络';
    } else {
      return '操作失败: ${e.toString()}';
    }
  }

  // 获取套餐列表（不需要认证）
  Future<Result<List<Package>>> getPackages() async {
    try {
      final response = await _client.get(
        Uri.parse('$_apiBase/packages/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true || json['success'] == null) {
          final data = json['data'] as List<dynamic>? ?? [];
          final packages = data.map((e) => Package.fromJson(e as Map<String, dynamic>)).toList();
          Logger.debug('获取套餐列表成功: ${packages.length} 个套餐');
          return Result.success(packages);
        } else {
          final message = json['message'] as String? ?? '获取套餐列表失败';
          Logger.error('获取套餐列表失败: $message');
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        Logger.error('获取套餐列表失败: ${response.statusCode}, 错误: $errorMessage');
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('获取套餐列表异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 创建订单
  Future<Result<Order>> createOrder({
    required int packageId,
    String paymentMethod = 'alipay',
    String? couponCode,
    bool useBalance = false,
    double balanceAmount = 0.0,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return Result.failure(Exception('未登录'));
      }

      final body = <String, dynamic>{
        'package_id': packageId,
        'payment_method': paymentMethod,
        if (couponCode != null) 'coupon_code': couponCode,
        'use_balance': useBalance,
        'balance_amount': balanceAmount,
      };

      final response = await _client.post(
        Uri.parse('$_apiBase/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['data'] as Map<String, dynamic>;
          final order = Order.fromJson(data);
          Logger.debug('创建订单成功: ${order.orderNo}');
          return Result.success(order);
        } else {
          final message = json['message'] as String? ?? '创建订单失败';
          Logger.error('创建订单失败: $message');
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        Logger.error('创建订单失败: ${response.statusCode}, 错误: $errorMessage');
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('创建订单异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  // 获取订单状态
  Future<Result<OrderStatus>> getOrderStatus(String orderNo) async {
    try {
      final token = await getToken();
      if (token == null) {
        return Result.failure(Exception('未登录'));
      }

      final response = await _client.get(
        Uri.parse('$_apiBase/orders/$orderNo/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['data'] as Map<String, dynamic>;
          final status = OrderStatus.fromJson(data);
          return Result.success(status);
        } else {
          final message = json['message'] as String? ?? '获取订单状态失败';
          return Result.failure(Exception(message));
        }
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        return Result.failure(Exception(errorMessage));
      }
    } catch (e) {
      Logger.error('获取订单状态异常: $e');
      final errorMsg = _getErrorMessage(e);
      return Result.failure(Exception(errorMsg));
    }
  }

  void dispose() {
    _client.close();
  }
}

// Result 类型用于处理成功/失败
class Result<T> {
  final T? data;
  final Exception? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R when<R>({
    required R Function(T) success,
    required R Function(Exception) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}


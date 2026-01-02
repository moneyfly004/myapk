// 认证相关的数据模型

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? verificationCode;
  final String? inviteCode;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.verificationCode,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (verificationCode != null) 'verification_code': verificationCode,
        if (inviteCode != null) 'invite_code': inviteCode,
      };
}

class LoginResponse {
  final String token;
  final String email;
  final String username;

  LoginResponse({
    required this.token,
    required this.email,
    required this.username,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return LoginResponse(
      token: data['access_token'] as String,
      email: user['email'] as String,
      username: user['username'] as String? ?? user['email'] as String,
    );
  }
}

class UserSubscription {
  final String universalUrl;
  final String expireTime;
  final int maxDevices;
  final int onlineDevices;

  UserSubscription({
    required this.universalUrl,
    required this.expireTime,
    required this.maxDevices,
    required this.onlineDevices,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      universalUrl: json['universal_url'] as String? ?? '',
      expireTime: json['expire_time'] as String? ?? '',
      maxDevices: json['max_devices'] as int? ?? 0,
      onlineDevices: json['online_devices'] as int? ?? 0,
    );
  }
}

class Package {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int durationDays;
  final int deviceLimit;
  final bool isRecommended;

  Package({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationDays,
    required this.deviceLimit,
    this.isRecommended = false,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: json['duration_days'] as int? ?? 0,
      deviceLimit: json['device_limit'] as int? ?? 0,
      isRecommended: json['is_recommended'] as bool? ?? false,
    );
  }
}

class Order {
  final String orderNo;
  final double amount;
  final double? finalAmount;
  final String status;
  final String? paymentUrl;
  final String? paymentQrCode;
  final DateTime? createdAt;
  final DateTime? paidAt;

  Order({
    required this.orderNo,
    required this.amount,
    this.finalAmount,
    required this.status,
    this.paymentUrl,
    this.paymentQrCode,
    this.createdAt,
    this.paidAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNo: json['order_no'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentUrl: json['payment_url'] as String?,
      paymentQrCode: json['payment_qr_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }
}

class OrderStatus {
  final String orderNo;
  final String status;
  final DateTime? paidAt;

  OrderStatus({
    required this.orderNo,
    required this.status,
    this.paidAt,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      orderNo: json['order_no'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }
}


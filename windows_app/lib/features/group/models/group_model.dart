import 'dart:convert';

// 分组类型
class GroupType {
  static const int basic = 0;
  static const int subscription = 1;
}

// 分组排序方式
class GroupOrder {
  static const int origin = 0; // 原始顺序
  static const int byDelay = 1; // 按延迟排序
  static const int byName = 2; // 按名称排序
}

// 分组模型
class ProxyGroup {
  final int id;
  final int userOrder;
  final bool ungrouped;
  final String? name;
  final int type;
  final String? subscriptionUrl;
  final String? subscriptionName;
  final String? subscriptionInfo;
  final int orderType;
  final bool isSelector;
  final int frontProxy;
  final int landingProxy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProxyGroup({
    required this.id,
    this.userOrder = 0,
    this.ungrouped = false,
    this.name,
    this.type = GroupType.basic,
    this.subscriptionUrl,
    this.subscriptionName,
    this.subscriptionInfo,
    this.orderType = GroupOrder.origin,
    this.isSelector = false,
    this.frontProxy = -1,
    this.landingProxy = -1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProxyGroup.fromMap(Map<String, dynamic> map) {
    return ProxyGroup(
      id: map['id'] as int,
      userOrder: map['user_order'] as int? ?? 0,
      ungrouped: (map['ungrouped'] as int? ?? 0) == 1,
      name: map['name'] as String?,
      type: map['type'] as int? ?? GroupType.basic,
      subscriptionUrl: map['subscription_url'] as String?,
      subscriptionName: map['subscription_name'] as String?,
      subscriptionInfo: map['subscription_info'] as String?,
      orderType: map['order_type'] as int? ?? GroupOrder.origin,
      isSelector: (map['is_selector'] as int? ?? 0) == 1,
      frontProxy: map['front_proxy'] as int? ?? -1,
      landingProxy: map['landing_proxy'] as int? ?? -1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_order': userOrder,
      'ungrouped': ungrouped ? 1 : 0,
      'name': name,
      'type': type,
      'subscription_url': subscriptionUrl,
      'subscription_name': subscriptionName,
      'subscription_info': subscriptionInfo,
      'order_type': orderType,
      'is_selector': isSelector ? 1 : 0,
      'front_proxy': frontProxy,
      'landing_proxy': landingProxy,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  String displayName() {
    return name ?? '默认分组';
  }

  ProxyGroup copyWith({
    int? id,
    int? userOrder,
    bool? ungrouped,
    String? name,
    int? type,
    String? subscriptionUrl,
    String? subscriptionName,
    String? subscriptionInfo,
    int? orderType,
    bool? isSelector,
    int? frontProxy,
    int? landingProxy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProxyGroup(
      id: id ?? this.id,
      userOrder: userOrder ?? this.userOrder,
      ungrouped: ungrouped ?? this.ungrouped,
      name: name ?? this.name,
      type: type ?? this.type,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      subscriptionName: subscriptionName ?? this.subscriptionName,
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
      orderType: orderType ?? this.orderType,
      isSelector: isSelector ?? this.isSelector,
      frontProxy: frontProxy ?? this.frontProxy,
      landingProxy: landingProxy ?? this.landingProxy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


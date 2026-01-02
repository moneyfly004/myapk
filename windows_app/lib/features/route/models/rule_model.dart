import 'dart:convert';

// 路由规则模型
class RuleEntity {
  final int id;
  final String name;
  final String config;
  final int userOrder;
  final bool enabled;
  final String domains;
  final String ip;
  final String port;
  final String sourcePort;
  final String network;
  final String source;
  final String protocol;
  final int outbound;
  final List<String> packages;
  final DateTime createdAt;
  final DateTime updatedAt;

  RuleEntity({
    required this.id,
    required this.name,
    this.config = '',
    this.userOrder = 0,
    this.enabled = false,
    this.domains = '',
    this.ip = '',
    this.port = '',
    this.sourcePort = '',
    this.network = '',
    this.source = '',
    this.protocol = '',
    this.outbound = 0,
    this.packages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory RuleEntity.fromMap(Map<String, dynamic> map) {
    return RuleEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      config: map['config'] as String? ?? '',
      userOrder: map['user_order'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 0) == 1,
      domains: map['domains'] as String? ?? '',
      ip: map['ip'] as String? ?? '',
      port: map['port'] as String? ?? '',
      sourcePort: map['source_port'] as String? ?? '',
      network: map['network'] as String? ?? '',
      source: map['source'] as String? ?? '',
      protocol: map['protocol'] as String? ?? '',
      outbound: map['outbound'] as int? ?? 0,
      packages: map['packages'] != null
          ? (map['packages'] as String).split(',').where((p) => p.isNotEmpty).toList()
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'config': config,
      'user_order': userOrder,
      'enabled': enabled ? 1 : 0,
      'domains': domains,
      'ip': ip,
      'port': port,
      'source_port': sourcePort,
      'network': network,
      'source': source,
      'protocol': protocol,
      'outbound': outbound,
      'packages': packages.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  String displayName() {
    return name.isNotEmpty ? name : '规则 $id';
  }

  String displayOutbound() {
    switch (outbound) {
      case 0:
        return '代理';
      case -1:
        return '直连';
      case -2:
        return '阻止';
      default:
        return '节点 $outbound';
    }
  }

  String mkSummary() {
    final parts = <String>[];
    if (config.isNotEmpty) parts.add('[config]');
    if (domains.isNotEmpty) parts.add(domains);
    if (ip.isNotEmpty) parts.add(ip);
    if (source.isNotEmpty) parts.add('src ip: $source');
    if (sourcePort.isNotEmpty) parts.add('src port: $sourcePort');
    if (port.isNotEmpty) parts.add('dst port: $port');
    if (network.isNotEmpty) parts.add('network: $network');
    if (protocol.isNotEmpty) parts.add('protocol: $protocol');
    if (packages.isNotEmpty) parts.add('应用: ${packages.length} 个');

    if (parts.length > 3) {
      return parts.sublist(0, 3).join('\n') + '\n...';
    }
    return parts.join('\n');
  }

  RuleEntity copyWith({
    int? id,
    String? name,
    String? config,
    int? userOrder,
    bool? enabled,
    String? domains,
    String? ip,
    String? port,
    String? sourcePort,
    String? network,
    String? source,
    String? protocol,
    int? outbound,
    List<String>? packages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RuleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      config: config ?? this.config,
      userOrder: userOrder ?? this.userOrder,
      enabled: enabled ?? this.enabled,
      domains: domains ?? this.domains,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      sourcePort: sourcePort ?? this.sourcePort,
      network: network ?? this.network,
      source: source ?? this.source,
      protocol: protocol ?? this.protocol,
      outbound: outbound ?? this.outbound,
      packages: packages ?? this.packages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


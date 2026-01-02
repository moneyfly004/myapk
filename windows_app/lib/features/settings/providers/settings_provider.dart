import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 设置键名（对应 Android 版本的 Key）
class SettingsKeys {
  // 通用设置
  static const String isAutoConnect = 'isAutoConnect';
  static const String appTheme = 'appTheme';
  static const String nightTheme = 'nightTheme';
  static const String serviceMode = 'serviceMode';
  static const String tunImplementation = 'tunImplementation';
  static const String mtu = 'mtu';
  static const String speedInterval = 'speedInterval';
  static const String profileTrafficStatistics = 'profileTrafficStatistics';
  static const String showDirectSpeed = 'showDirectSpeed';
  static const String showGroupInNotification = 'showGroupInNotification';
  static const String alwaysShowAddress = 'alwaysShowAddress';
  static const String meteredNetwork = 'meteredNetwork';
  static const String acquireWakeLock = 'acquireWakeLock';
  static const String logLevel = 'logLevel';
  static const String globalCustomConfig = 'globalCustomConfig';
  
  // 路由设置
  static const String proxyApps = 'proxyApps';
  static const String bypassLan = 'bypassLan';
  static const String bypassLanInCore = 'bypassLanInCore';
  static const String trafficSniffing = 'trafficSniffing';
  static const String resolveDestination = 'resolveDestination';
  static const String ipv6Mode = 'ipv6Mode';
  static const String rulesProvider = 'rulesProvider';
  
  // DNS设置
  static const String remoteDns = 'remoteDns';
  static const String directDns = 'directDns';
  static const String enableDnsRouting = 'enableDnsRouting';
  static const String enableFakeDns = 'enableFakeDns';
  
  // 入站设置
  static const String mixedPort = 'mixedPort';
  static const String appendHttpProxy = 'appendHttpProxy';
  static const String allowAccess = 'allowAccess';
  
  // 其他
  static const String connectionTestURL = 'connectionTestURL';
  static const String enableClashAPI = 'enableClashAPI';
  static const String networkChangeResetConnections = 'networkChangeResetConnections';
  static const String wakeResetConnections = 'wakeResetConnections';
  static const String globalAllowInsecure = 'globalAllowInsecure';
  static const String allowInsecureOnRequest = 'allowInsecureOnRequest';
  static const String appTLSVersion = 'appTLSVersion';
  static const String showBottomBar = 'showBottomBar';
}

// 设置状态
class SettingsState {
  // 通用设置
  final bool isAutoConnect;
  final int appTheme;
  final int nightTheme;
  final String serviceMode;
  final int tunImplementation;
  final int mtu;
  final int speedInterval;
  final bool profileTrafficStatistics;
  final bool showDirectSpeed;
  final bool showGroupInNotification;
  final bool alwaysShowAddress;
  final bool meteredNetwork;
  final bool acquireWakeLock;
  final int logLevel;
  final String globalCustomConfig;
  
  // 路由设置
  final bool proxyApps;
  final bool bypassLan;
  final bool bypassLanInCore;
  final int trafficSniffing;
  final bool resolveDestination;
  final int ipv6Mode;
  final int rulesProvider;
  
  // DNS设置
  final String remoteDns;
  final String directDns;
  final bool enableDnsRouting;
  final bool enableFakeDns;
  
  // 入站设置
  final int mixedPort;
  final bool appendHttpProxy;
  final bool allowAccess;
  
  // 其他
  final String connectionTestURL;
  final bool enableClashAPI;
  final bool networkChangeResetConnections;
  final bool wakeResetConnections;
  final bool globalAllowInsecure;
  final bool allowInsecureOnRequest;
  final String appTLSVersion;
  final bool showBottomBar;

  SettingsState({
    this.isAutoConnect = false,
    this.appTheme = 0,
    this.nightTheme = 0,
    this.serviceMode = 'vpn',
    this.tunImplementation = 0,
    this.mtu = 9000,
    this.speedInterval = 1000,
    this.profileTrafficStatistics = true,
    this.showDirectSpeed = true,
    this.showGroupInNotification = false,
    this.alwaysShowAddress = false,
    this.meteredNetwork = false,
    this.acquireWakeLock = false,
    this.logLevel = 0,
    this.globalCustomConfig = '',
    this.proxyApps = false,
    this.bypassLan = true,
    this.bypassLanInCore = false,
    this.trafficSniffing = 1,
    this.resolveDestination = false,
    this.ipv6Mode = 0,
    this.rulesProvider = 0,
    this.remoteDns = 'https://dns.google/dns-query',
    this.directDns = 'https://223.5.5.5/dns-query',
    this.enableDnsRouting = true,
    this.enableFakeDns = true,
    this.mixedPort = 2080,
    this.appendHttpProxy = false,
    this.allowAccess = false,
    this.connectionTestURL = 'http://cp.cloudflare.com/',
    this.enableClashAPI = false,
    this.networkChangeResetConnections = true,
    this.wakeResetConnections = false,
    this.globalAllowInsecure = false,
    this.allowInsecureOnRequest = false,
    this.appTLSVersion = '1.2',
    this.showBottomBar = true,
  });

  SettingsState copyWith({
    bool? isAutoConnect,
    int? appTheme,
    int? nightTheme,
    String? serviceMode,
    int? tunImplementation,
    int? mtu,
    int? speedInterval,
    bool? profileTrafficStatistics,
    bool? showDirectSpeed,
    bool? showGroupInNotification,
    bool? alwaysShowAddress,
    bool? meteredNetwork,
    bool? acquireWakeLock,
    int? logLevel,
    String? globalCustomConfig,
    bool? proxyApps,
    bool? bypassLan,
    bool? bypassLanInCore,
    int? trafficSniffing,
    bool? resolveDestination,
    int? ipv6Mode,
    int? rulesProvider,
    String? remoteDns,
    String? directDns,
    bool? enableDnsRouting,
    bool? enableFakeDns,
    int? mixedPort,
    bool? appendHttpProxy,
    bool? allowAccess,
    String? connectionTestURL,
    bool? enableClashAPI,
    bool? networkChangeResetConnections,
    bool? wakeResetConnections,
    bool? globalAllowInsecure,
    bool? allowInsecureOnRequest,
    String? appTLSVersion,
    bool? showBottomBar,
  }) {
    return SettingsState(
      isAutoConnect: isAutoConnect ?? this.isAutoConnect,
      appTheme: appTheme ?? this.appTheme,
      nightTheme: nightTheme ?? this.nightTheme,
      serviceMode: serviceMode ?? this.serviceMode,
      tunImplementation: tunImplementation ?? this.tunImplementation,
      mtu: mtu ?? this.mtu,
      speedInterval: speedInterval ?? this.speedInterval,
      profileTrafficStatistics: profileTrafficStatistics ?? this.profileTrafficStatistics,
      showDirectSpeed: showDirectSpeed ?? this.showDirectSpeed,
      showGroupInNotification: showGroupInNotification ?? this.showGroupInNotification,
      alwaysShowAddress: alwaysShowAddress ?? this.alwaysShowAddress,
      meteredNetwork: meteredNetwork ?? this.meteredNetwork,
      acquireWakeLock: acquireWakeLock ?? this.acquireWakeLock,
      logLevel: logLevel ?? this.logLevel,
      globalCustomConfig: globalCustomConfig ?? this.globalCustomConfig,
      proxyApps: proxyApps ?? this.proxyApps,
      bypassLan: bypassLan ?? this.bypassLan,
      bypassLanInCore: bypassLanInCore ?? this.bypassLanInCore,
      trafficSniffing: trafficSniffing ?? this.trafficSniffing,
      resolveDestination: resolveDestination ?? this.resolveDestination,
      ipv6Mode: ipv6Mode ?? this.ipv6Mode,
      rulesProvider: rulesProvider ?? this.rulesProvider,
      remoteDns: remoteDns ?? this.remoteDns,
      directDns: directDns ?? this.directDns,
      enableDnsRouting: enableDnsRouting ?? this.enableDnsRouting,
      enableFakeDns: enableFakeDns ?? this.enableFakeDns,
      mixedPort: mixedPort ?? this.mixedPort,
      appendHttpProxy: appendHttpProxy ?? this.appendHttpProxy,
      allowAccess: allowAccess ?? this.allowAccess,
      connectionTestURL: connectionTestURL ?? this.connectionTestURL,
      enableClashAPI: enableClashAPI ?? this.enableClashAPI,
      networkChangeResetConnections: networkChangeResetConnections ?? this.networkChangeResetConnections,
      wakeResetConnections: wakeResetConnections ?? this.wakeResetConnections,
      globalAllowInsecure: globalAllowInsecure ?? this.globalAllowInsecure,
      allowInsecureOnRequest: allowInsecureOnRequest ?? this.allowInsecureOnRequest,
      appTLSVersion: appTLSVersion ?? this.appTLSVersion,
      showBottomBar: showBottomBar ?? this.showBottomBar,
    );
  }
}

// 设置 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      isAutoConnect: prefs.getBool(SettingsKeys.isAutoConnect) ?? false,
      appTheme: prefs.getInt(SettingsKeys.appTheme) ?? 0,
      nightTheme: prefs.getInt(SettingsKeys.nightTheme) ?? 0,
      serviceMode: prefs.getString(SettingsKeys.serviceMode) ?? 'vpn',
      tunImplementation: prefs.getInt(SettingsKeys.tunImplementation) ?? 0,
      mtu: prefs.getInt(SettingsKeys.mtu) ?? 9000,
      speedInterval: prefs.getInt(SettingsKeys.speedInterval) ?? 1000,
      profileTrafficStatistics: prefs.getBool(SettingsKeys.profileTrafficStatistics) ?? true,
      showDirectSpeed: prefs.getBool(SettingsKeys.showDirectSpeed) ?? true,
      showGroupInNotification: prefs.getBool(SettingsKeys.showGroupInNotification) ?? false,
      alwaysShowAddress: prefs.getBool(SettingsKeys.alwaysShowAddress) ?? false,
      meteredNetwork: prefs.getBool(SettingsKeys.meteredNetwork) ?? false,
      acquireWakeLock: prefs.getBool(SettingsKeys.acquireWakeLock) ?? false,
      logLevel: prefs.getInt(SettingsKeys.logLevel) ?? 0,
      globalCustomConfig: prefs.getString(SettingsKeys.globalCustomConfig) ?? '',
      proxyApps: prefs.getBool(SettingsKeys.proxyApps) ?? false,
      bypassLan: prefs.getBool(SettingsKeys.bypassLan) ?? true,
      bypassLanInCore: prefs.getBool(SettingsKeys.bypassLanInCore) ?? false,
      trafficSniffing: prefs.getInt(SettingsKeys.trafficSniffing) ?? 1,
      resolveDestination: prefs.getBool(SettingsKeys.resolveDestination) ?? false,
      ipv6Mode: prefs.getInt(SettingsKeys.ipv6Mode) ?? 0,
      rulesProvider: prefs.getInt(SettingsKeys.rulesProvider) ?? 0,
      remoteDns: prefs.getString(SettingsKeys.remoteDns) ?? 'https://dns.google/dns-query',
      directDns: prefs.getString(SettingsKeys.directDns) ?? 'https://223.5.5.5/dns-query',
      enableDnsRouting: prefs.getBool(SettingsKeys.enableDnsRouting) ?? true,
      enableFakeDns: prefs.getBool(SettingsKeys.enableFakeDns) ?? true,
      mixedPort: prefs.getInt(SettingsKeys.mixedPort) ?? 2080,
      appendHttpProxy: prefs.getBool(SettingsKeys.appendHttpProxy) ?? false,
      allowAccess: prefs.getBool(SettingsKeys.allowAccess) ?? false,
      connectionTestURL: prefs.getString(SettingsKeys.connectionTestURL) ?? 'http://cp.cloudflare.com/',
      enableClashAPI: prefs.getBool(SettingsKeys.enableClashAPI) ?? false,
      networkChangeResetConnections: prefs.getBool(SettingsKeys.networkChangeResetConnections) ?? true,
      wakeResetConnections: prefs.getBool(SettingsKeys.wakeResetConnections) ?? false,
      globalAllowInsecure: prefs.getBool(SettingsKeys.globalAllowInsecure) ?? false,
      allowInsecureOnRequest: prefs.getBool(SettingsKeys.allowInsecureOnRequest) ?? false,
      appTLSVersion: prefs.getString(SettingsKeys.appTLSVersion) ?? '1.2',
      showBottomBar: prefs.getBool(SettingsKeys.showBottomBar) ?? true,
    );
  }

  Future<void> updateSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    
    // 更新状态
    switch (key) {
      case SettingsKeys.isAutoConnect:
        state = state.copyWith(isAutoConnect: value as bool);
        break;
      case SettingsKeys.appTheme:
        state = state.copyWith(appTheme: value as int);
        break;
      case SettingsKeys.nightTheme:
        state = state.copyWith(nightTheme: value as int);
        break;
      case SettingsKeys.serviceMode:
        state = state.copyWith(serviceMode: value as String);
        break;
      case SettingsKeys.tunImplementation:
        state = state.copyWith(tunImplementation: value as int);
        break;
      case SettingsKeys.mtu:
        state = state.copyWith(mtu: value as int);
        break;
      case SettingsKeys.speedInterval:
        state = state.copyWith(speedInterval: value as int);
        break;
      case SettingsKeys.profileTrafficStatistics:
        state = state.copyWith(profileTrafficStatistics: value as bool);
        break;
      case SettingsKeys.showDirectSpeed:
        state = state.copyWith(showDirectSpeed: value as bool);
        break;
      case SettingsKeys.showGroupInNotification:
        state = state.copyWith(showGroupInNotification: value as bool);
        break;
      case SettingsKeys.alwaysShowAddress:
        state = state.copyWith(alwaysShowAddress: value as bool);
        break;
      case SettingsKeys.meteredNetwork:
        state = state.copyWith(meteredNetwork: value as bool);
        break;
      case SettingsKeys.acquireWakeLock:
        state = state.copyWith(acquireWakeLock: value as bool);
        break;
      case SettingsKeys.logLevel:
        state = state.copyWith(logLevel: value as int);
        break;
      case SettingsKeys.globalCustomConfig:
        state = state.copyWith(globalCustomConfig: value as String);
        break;
      case SettingsKeys.proxyApps:
        state = state.copyWith(proxyApps: value as bool);
        break;
      case SettingsKeys.bypassLan:
        state = state.copyWith(bypassLan: value as bool);
        break;
      case SettingsKeys.bypassLanInCore:
        state = state.copyWith(bypassLanInCore: value as bool);
        break;
      case SettingsKeys.trafficSniffing:
        state = state.copyWith(trafficSniffing: value as int);
        break;
      case SettingsKeys.resolveDestination:
        state = state.copyWith(resolveDestination: value as bool);
        break;
      case SettingsKeys.ipv6Mode:
        state = state.copyWith(ipv6Mode: value as int);
        break;
      case SettingsKeys.rulesProvider:
        state = state.copyWith(rulesProvider: value as int);
        break;
      case SettingsKeys.remoteDns:
        state = state.copyWith(remoteDns: value as String);
        break;
      case SettingsKeys.directDns:
        state = state.copyWith(directDns: value as String);
        break;
      case SettingsKeys.enableDnsRouting:
        state = state.copyWith(enableDnsRouting: value as bool);
        break;
      case SettingsKeys.enableFakeDns:
        state = state.copyWith(enableFakeDns: value as bool);
        break;
      case SettingsKeys.mixedPort:
        state = state.copyWith(mixedPort: value as int);
        break;
      case SettingsKeys.appendHttpProxy:
        state = state.copyWith(appendHttpProxy: value as bool);
        break;
      case SettingsKeys.allowAccess:
        state = state.copyWith(allowAccess: value as bool);
        break;
      case SettingsKeys.connectionTestURL:
        state = state.copyWith(connectionTestURL: value as String);
        break;
      case SettingsKeys.enableClashAPI:
        state = state.copyWith(enableClashAPI: value as bool);
        break;
      case SettingsKeys.networkChangeResetConnections:
        state = state.copyWith(networkChangeResetConnections: value as bool);
        break;
      case SettingsKeys.wakeResetConnections:
        state = state.copyWith(wakeResetConnections: value as bool);
        break;
      case SettingsKeys.globalAllowInsecure:
        state = state.copyWith(globalAllowInsecure: value as bool);
        break;
      case SettingsKeys.allowInsecureOnRequest:
        state = state.copyWith(allowInsecureOnRequest: value as bool);
        break;
      case SettingsKeys.appTLSVersion:
        state = state.copyWith(appTLSVersion: value as String);
        break;
      case SettingsKeys.showBottomBar:
        state = state.copyWith(showBottomBar: value as bool);
        break;
    }
  }
}


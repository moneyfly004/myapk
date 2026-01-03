import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../widgets/cyberpunk/neon_button.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_models.dart';
import 'dart:async';

class PackagePurchasePage extends ConsumerStatefulWidget {
  const PackagePurchasePage({super.key});

  @override
  ConsumerState<PackagePurchasePage> createState() => _PackagePurchasePageState();
}

class _PackagePurchasePageState extends ConsumerState<PackagePurchasePage> {
  final AuthRepository _authRepository = AuthRepository();
  List<Package> _packages = [];
  bool _isLoading = true;
  String? _error;
    Timer? _paymentStatusTimer;
  webview_flutter.WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    _authRepository.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authRepository.getPackages();
      result.when(
        success: (packages) {
          setState(() {
            _packages = packages;
            _isLoading = false;
          });
        },
        failure: (error) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package pkg) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '确认购买', fontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('套餐：${pkg.name}', style: const TextStyle(color: CyberpunkTheme.textPrimary)),
            Text('价格：¥${pkg.price}', style: const TextStyle(color: CyberpunkTheme.textPrimary)),
            Text('有效期：${pkg.durationDays}天', style: const TextStyle(color: CyberpunkTheme.textPrimary)),
            Text('设备限制：${pkg.deviceLimit}个', style: const TextStyle(color: CyberpunkTheme.textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const NeonText(text: '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const NeonText(
              text: '确认购买',
              neonColor: CyberpunkTheme.primaryNeon,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _createOrder(pkg);
  }

  Future<void> _createOrder(Package pkg) async {
    try {
      final result = await _authRepository.createOrder(
        packageId: pkg.id,
        paymentMethod: 'alipay',
      );

      result.when(
        success: (order) {
          // 订单已创建，开始支付流程

          if (order.status == 'paid') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('订单已支付成功')),
            );
            _updateSubscription();
          } else if (order.paymentUrl != null || order.paymentQrCode != null) {
            _showPaymentDialog(order);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('支付链接生成失败')),
            );
          }
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建订单失败: ${error.toString()}')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建订单失败: $e')),
      );
    }
  }

  void _showPaymentDialog(Order order) {
    final paymentUrl = order.paymentUrl ?? order.paymentQrCode;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付链接生成失败，请稍后重试')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: Column(
          children: [
            const NeonText(text: '支付订单', fontSize: 18),
            const SizedBox(height: 8),
            Text(
              '订单号: ${order.orderNo}',
              style: const TextStyle(
                color: CyberpunkTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '金额: ¥${order.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: CyberpunkTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: webview_flutter.WebViewWidget(
                  controller: (_webViewController ??= webview_flutter.WebViewController()
                    ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
                    ..setNavigationDelegate(
                      webview_flutter.NavigationDelegate(
                        onNavigationRequest: (request) {
                          // 处理 alipays:// 协议
                          if (request.url.startsWith('alipays://')) {
                            launchUrl(
                              Uri.parse(request.url),
                              mode: LaunchMode.externalApplication,
                            );
                            return webview_flutter.NavigationDecision.prevent;
                          }
                          return webview_flutter.NavigationDecision.navigate;
                        },
                      ),
                    )
                    ..loadRequest(Uri.parse(paymentUrl))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _checkPaymentStatus(order.orderNo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.primaryNeon,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('检查支付状态'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _paymentStatusTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // 开始自动检查支付状态
    _startPaymentStatusCheck(order.orderNo);
  }

  void _startPaymentStatusCheck(String orderNo) {
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final result = await _authRepository.getOrderStatus(orderNo);
      result.when(
        success: (status) {
          if (status.status == 'paid') {
            timer.cancel();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('支付成功！')),
            );
            _updateSubscription();
          }
        },
        failure: (_) {
          // 静默失败，继续检查
        },
      );
    });
  }

  Future<void> _checkPaymentStatus(String orderNo) async {
    try {
      final result = await _authRepository.getOrderStatus(orderNo);
      result.when(
        success: (status) {
          if (status.status == 'paid') {
            _paymentStatusTimer?.cancel();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('支付成功！')),
            );
            _updateSubscription();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('支付状态: ${status.status}')),
            );
          }
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('检查失败: ${error.toString()}')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查失败: $e')),
      );
    }
  }

  Future<void> _updateSubscription() async {
    try {
      final result = await _authRepository.getUserSubscription();
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('订阅信息已更新')),
          );
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新订阅失败: ${error.toString()}')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新订阅失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '套餐购买',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: CyberpunkTheme.primaryNeon),
            onPressed: _loadPackages,
            tooltip: '刷新',
          ),
        ],
      ),
      body: GridBackground(
        gridColor: CyberpunkTheme.primaryNeon,
        gridSize: 20.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkGradients.backgroundGradient,
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CyberpunkTheme.primaryNeon,
                    ),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          NeonText(
                            text: '加载失败',
                            fontSize: 18,
                            neonColor: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          NeonText(
                            text: _error!,
                            fontSize: 14,
                            neonColor: CyberpunkTheme.textSecondary,
                          ),
                          const SizedBox(height: 24),
                          NeonButton(
                            onPressed: _loadPackages,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    )
                  : _packages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 64,
                                color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const NeonText(
                                text: '暂无套餐',
                                fontSize: 18,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final pkg = _packages[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildPackageCard(pkg),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package pkg) {
    return NeonCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NeonText(
                      text: pkg.name,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    NeonText(
                      text: pkg.description ?? '',
                      fontSize: 14,
                      neonColor: CyberpunkTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              NeonText(
                text: '¥${pkg.price.toStringAsFixed(2)}',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                neonColor: CyberpunkTheme.primaryNeon,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_today, '${pkg.durationDays}天'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.devices, '${pkg.deviceLimit}设备'),
            ],
          ),
          const SizedBox(height: 16),
          NeonButton(
            onPressed: () => _purchasePackage(pkg),
            child: const Text('立即购买'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CyberpunkTheme.darkerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CyberpunkTheme.primaryNeon.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CyberpunkTheme.primaryNeon),
          const SizedBox(width: 4),
          NeonText(
            text: text,
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}


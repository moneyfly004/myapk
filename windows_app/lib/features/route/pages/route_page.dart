import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../providers/route_provider.dart';
import '../models/rule_model.dart';

class RoutePage extends ConsumerStatefulWidget {
  const RoutePage({super.key});

  @override
  ConsumerState<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends ConsumerState<RoutePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '路由',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: CyberpunkTheme.primaryNeon),
            onPressed: () {
              // TODO: 添加新路由规则
              _showAddRouteDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: CyberpunkTheme.primaryNeon),
            onPressed: () {
              // TODO: 重置路由规则
              _showResetRouteDialog(context);
            },
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
          child: Consumer(
            builder: (context, ref, child) {
              final ruleState = ref.watch(ruleListProvider);
              
              if (ruleState.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CyberpunkTheme.primaryNeon,
                    ),
                  ),
                );
              }
              
              if (ruleState.error != null) {
                return Center(
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
                        text: ruleState.error!,
                        fontSize: 14,
                        neonColor: CyberpunkTheme.textSecondary,
                      ),
                    ],
                  ),
                );
              }
              
              if (ruleState.rules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route,
                          size: 64,
                          color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const NeonText(
                          text: '暂无路由规则',
                          fontSize: 16,
                        ),
                        const SizedBox(height: 8),
                        NeonText(
                          text: '点击右上角 + 添加路由规则',
                          fontSize: 12,
                          neonColor: CyberpunkTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: ruleState.rules.length,
                itemBuilder: (context, index) {
                  final rule = ruleState.rules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildRuleItem(context, rule),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, RuleEntity rule) {
    return NeonCard(
      padding: const EdgeInsets.all(16.0),
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
                      text: rule.displayName(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    NeonText(
                      text: rule.displayOutbound(),
                      fontSize: 12,
                      neonColor: CyberpunkTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: (value) async {
                  await ref.read(ruleListProvider.notifier).toggleRule(rule.id!, value);
                },
                activeColor: CyberpunkTheme.primaryNeon,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: CyberpunkTheme.darkerBackground,
                      title: const NeonText(text: '删除规则', fontSize: 18),
                      content: Text(
                        '确定要删除 "${rule.displayName()}" 吗？',
                        style: const TextStyle(color: CyberpunkTheme.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const NeonText(text: '取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const NeonText(
                            text: '删除',
                            neonColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await ref.read(ruleListProvider.notifier).deleteRule(rule.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('规则已删除')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          if (rule.mkSummary().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rule.mkSummary(),
              style: const TextStyle(
                color: CyberpunkTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddRouteDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedOutbound = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CyberpunkTheme.darkerBackground,
          title: const NeonText(text: '添加路由规则', fontSize: 18),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: CyberpunkTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '规则名称',
                    labelStyle: TextStyle(color: CyberpunkTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedOutbound,
                  dropdownColor: CyberpunkTheme.darkerBackground,
                  style: const TextStyle(color: CyberpunkTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '出站动作',
                    labelStyle: TextStyle(color: CyberpunkTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('代理')),
                    DropdownMenuItem(value: -1, child: Text('直连')),
                    DropdownMenuItem(value: -2, child: Text('阻止')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedOutbound = value ?? 0;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const NeonText(text: '取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入规则名称')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                
                final notifier = ref.read(ruleListProvider.notifier);
                final id = await notifier.createRule(
                  name: nameController.text,
                  outbound: selectedOutbound,
                );
                
                if (id > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('规则创建成功')),
                  );
                }
              },
              child: const NeonText(
                text: '确定',
                neonColor: CyberpunkTheme.primaryNeon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetRouteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '重置路由规则', fontSize: 18),
        content: const Text(
          '确定要重置所有路由规则吗？此操作将删除所有自定义规则。',
          style: TextStyle(color: CyberpunkTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const NeonText(text: '取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: 实现重置路由规则的逻辑（删除所有规则）
              final notifier = ref.read(ruleListProvider.notifier);
              final rules = ref.read(ruleListProvider).rules;
              
              for (final rule in rules) {
                await notifier.deleteRule(rule.id);
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('路由规则已重置')),
                );
              }
            },
            child: const NeonText(
              text: '确定',
              neonColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}


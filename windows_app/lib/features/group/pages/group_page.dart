import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';

import '../providers/group_provider.dart';
import '../models/group_model.dart';

import '../../../core/config/database.dart';

class GroupPage extends ConsumerStatefulWidget {
  const GroupPage({super.key});

  @override
  ConsumerState<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends ConsumerState<GroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '分组',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: CyberpunkTheme.primaryNeon),
            onPressed: () {
              // TODO: 添加新分组
              _showAddGroupDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: CyberpunkTheme.primaryNeon),
            onPressed: () {
              // TODO: 更新所有订阅
              _showUpdateAllDialog(context);
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
              final groupState = ref.watch(groupListProvider);
              
              if (groupState.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CyberpunkTheme.primaryNeon,
                    ),
                  ),
                );
              }
              
              if (groupState.error != null) {
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
                        text: groupState.error!,
                        fontSize: 14,
                        neonColor: CyberpunkTheme.textSecondary,
                      ),
                    ],
                  ),
                );
              }
              
              if (groupState.groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const NeonText(
                        text: '暂无分组',
                        fontSize: 18,
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: groupState.groups.length,
                itemBuilder: (context, index) {
                  final group = groupState.groups[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildGroupItem(
                      context,
                      group: group,
                      onTap: () {
                        // TODO: 打开分组详情
                      },
                      onDelete: group.ungrouped ? null : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: CyberpunkTheme.darkerBackground,
                            title: const NeonText(text: '删除分组', fontSize: 18),
                            content: Text(
                              '确定要删除 "${group.displayName()}" 吗？',
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
                          await ref.read(groupListProvider.notifier).deleteGroup(group.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('分组已删除')),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGroupItem(
    BuildContext context, {
    required ProxyGroup group,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    final typeName = group.type == GroupType.subscription ? '订阅' : '基础';
    
    return FutureBuilder<int>(
      future: AppDatabase().queryNodesByGroup(group.id).then((nodes) => nodes.length),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildGroupItemContent(
          context,
          name: group.displayName(),
          type: typeName,
          nodeCount: count,
          onTap: onTap,
          onDelete: onDelete,
        );
      },
    );
  }

  Widget _buildGroupItemContent(
    BuildContext context, {
    required String name,
    required String type,
    required int nodeCount,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return NeonCard(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              type == '订阅' ? Icons.cloud : Icons.folder,
              color: CyberpunkTheme.primaryNeon,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeonText(
                    text: name,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  NeonText(
                    text: '$type · $nodeCount 个节点',
                    fontSize: 12,
                    neonColor: CyberpunkTheme.textSecondary,
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmDialog(context, name, onDelete);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    int selectedType = GroupType.basic;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: CyberpunkTheme.darkerBackground,
          title: const NeonText(text: '添加分组', fontSize: 18),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: CyberpunkTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '分组名称',
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
                  value: selectedType,
                  dropdownColor: CyberpunkTheme.darkerBackground,
                  style: const TextStyle(color: CyberpunkTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: '分组类型',
                    labelStyle: TextStyle(color: CyberpunkTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: GroupType.basic, child: Text('基础分组')),
                    DropdownMenuItem(value: GroupType.subscription, child: Text('订阅分组')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? GroupType.basic;
                    });
                  },
                ),
                if (selectedType == GroupType.subscription) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: CyberpunkTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: '订阅链接',
                      labelStyle: TextStyle(color: CyberpunkTheme.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: CyberpunkTheme.primaryNeon),
                      ),
                    ),
                  ),
                ],
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
                    const SnackBar(content: Text('请输入分组名称')),
                  );
                  return;
                }
                
                if (selectedType == GroupType.subscription && urlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入订阅链接')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                
                final notifier = ref.read(groupListProvider.notifier);
                final id = await notifier.createGroup(
                  name: nameController.text,
                  type: selectedType,
                  subscriptionUrl: selectedType == GroupType.subscription ? urlController.text : null,
                );
                
                if (id > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('分组创建成功')),
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

  void _showUpdateAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '更新所有订阅', fontSize: 18),
        content: const Text(
          '确定要更新所有订阅吗？',
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
              // TODO: 实现更新所有订阅的逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('更新功能开发中...')),
              );
            },
            child: const NeonText(
              text: '确定',
              neonColor: CyberpunkTheme.primaryNeon,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String name,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '删除分组', fontSize: 18),
        content: Text(
          '确定要删除 "$name" 吗？',
          style: const TextStyle(color: CyberpunkTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const NeonText(text: '取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const NeonText(
              text: '删除',
              neonColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}


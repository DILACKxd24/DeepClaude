import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_manager.dart';
import '../models/provider_config.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        title: const Text(
          '模型配置',
          style: TextStyle(color: Color(0xFF1a1a1a)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1a1a1a)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD97706)),
            onPressed: () => _showAddProviderDialog(context),
            tooltip: '添加自定义供应商',
          ),
        ],
      ),
      body: Consumer<ProviderManager>(
        builder: (context, manager, _) {
          if (manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 当前配置信息
              _buildCurrentConfigCard(context, manager),
              
              const SizedBox(height: 24),
              
              // 供应商列表
              const Text(
                '选择供应商',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 12),
              
              ...manager.providers.map((provider) {
                return _ProviderCard(
                  provider: provider,
                  isSelected: manager.currentProvider?.id == provider.id,
                  onTap: () => manager.setCurrentProvider(provider),
                  onEdit: () => _showEditProviderDialog(context, provider),
                  onDelete: provider.isOfficial
                      ? null
                      : () => _confirmDelete(context, manager, provider),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentConfigCard(BuildContext context, ProviderManager manager) {
    final current = manager.currentProvider;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前配置',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      current?.name ?? '未选择',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                  ],
                ),
              ),
              if (current?.websiteUrl != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  color: Colors.grey,
                  onPressed: () => _launchUrl(current!.websiteUrl!),
                  tooltip: '访问官网',
                ),
            ],
          ),
          if (current != null && !current.isOfficial) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildConfigRow('Base URL', current.baseUrl ?? '默认'),
            _buildConfigRow('Model', current.model ?? '默认'),
            _buildConfigRow('API Key', current.authToken != null ? '••••••••' : '未设置'),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1a1a1a),
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProviderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ProviderEditDialog(),
    );
  }

  void _showEditProviderDialog(BuildContext context, ProviderConfig provider) {
    showDialog(
      context: context,
      builder: (context) => _ProviderEditDialog(provider: provider),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProviderManager manager,
    ProviderConfig provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除供应商 "${provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              manager.deleteProvider(provider.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) {
    // URL launching is optional - just show a snackbar for now
    debugPrint('Opening URL: $url');
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderConfig provider;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFD97706)
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // 名称和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        if (provider.isOfficial) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '官方',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.model ?? '默认模型',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFD97706),
                  size: 20,
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.grey,
                  onPressed: onEdit,
                  tooltip: '编辑',
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.grey,
                    onPressed: onDelete,
                    tooltip: '删除',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (provider.iconName) {
      case 'anthropic':
        return Icons.auto_awesome;
      case 'deepseek':
        return Icons.psychology;
      case 'zhipu':
        return Icons.smart_toy;
      case 'qwen':
        return Icons.cloud;
      case 'kimi':
        return Icons.nightlight;
      case 'openrouter':
        return Icons.router;
      default:
        return Icons.api;
    }
  }

  Color _getIconColor() {
    if (provider.iconColor != null) {
      try {
        return Color(
          int.parse(provider.iconColor!.replaceFirst('#', '0xFF')),
        );
      } catch (_) {}
    }
    return const Color(0xFF6366F1);
  }
}

class _ProviderEditDialog extends StatefulWidget {
  final ProviderConfig? provider;

  const _ProviderEditDialog({this.provider});

  @override
  State<_ProviderEditDialog> createState() => _ProviderEditDialogState();
}

class _ProviderEditDialogState extends State<_ProviderEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _authTokenController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _baseUrlController = TextEditingController(text: widget.provider?.baseUrl ?? '');
    _authTokenController = TextEditingController(text: widget.provider?.authToken ?? '');
    _modelController = TextEditingController(text: widget.provider?.model ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _authTokenController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.provider != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑供应商' : '添加供应商'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如: My Provider',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.example.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authTokenController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: '例如: claude-3-5-sonnet',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
          ),
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入名称')),
      );
      return;
    }

    final manager = context.read<ProviderManager>();
    
    final provider = ProviderConfig(
      id: widget.provider?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      baseUrl: _baseUrlController.text.trim().isEmpty
          ? null
          : _baseUrlController.text.trim(),
      authToken: _authTokenController.text.trim().isEmpty
          ? null
          : _authTokenController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      haikuModel: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      sonnetModel: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      opusModel: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
    );

    if (widget.provider != null) {
      manager.updateProvider(provider);
    } else {
      manager.addProvider(provider);
    }

    Navigator.pop(context);
  }
}

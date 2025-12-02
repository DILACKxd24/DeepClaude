import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcp_provider.dart';
import '../models/mcp_server.dart';

/// MCP 设置面板
class McpSettingsSection extends StatelessWidget {
  const McpSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<McpProvider>(
      builder: (context, mcpProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和添加按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MCP Servers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                _AddServerButton(
                  onAdd: () => _showAddServerDialog(context, mcpProvider),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure Model Context Protocol servers for extended capabilities',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // 服务器列表
            if (mcpProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (mcpProvider.servers.isEmpty)
              _EmptyState(onAdd: () => _showAddServerDialog(context, mcpProvider))
            else
              ...mcpProvider.servers.map((server) => _McpServerCard(
                server: server,
                onToggle: (enabled) => mcpProvider.toggleServer(server.id, enabled),
                onEdit: () => _showEditServerDialog(context, mcpProvider, server),
                onDelete: () => _confirmDelete(context, mcpProvider, server),
                onTest: () => mcpProvider.testConnection(server.id),
              )),
          ],
        );
      },
    );
  }

  void _showAddServerDialog(BuildContext context, McpProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddEditServerDialog(
        onSave: (name, description, transport, originalJson) async {
          await provider.addServer(
            name: name,
            description: description,
            transport: transport,
            originalJson: originalJson,
          );
        },
      ),
    );
  }

  void _showEditServerDialog(BuildContext context, McpProvider provider, McpServer server) {
    showDialog(
      context: context,
      builder: (context) => _AddEditServerDialog(
        server: server,
        onSave: (name, description, transport, originalJson) async {
          await provider.updateServer(server.copyWith(
            name: name,
            description: description,
            transport: transport,
            originalJson: originalJson,
          ));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, McpProvider provider, McpServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete MCP Server'),
        content: Text('Are you sure you want to delete "${server.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteServer(server.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// 添加服务器按钮
class _AddServerButton extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddServerButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'add') {
          onAdd();
        } else if (value == 'import') {
          _showImportDialog(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('Add Server'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_upload, size: 18),
              SizedBox(width: 8),
              Text('Import from JSON'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import MCP Servers'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste your MCP configuration JSON:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: '{\n  "mcpServers": {\n    "server-name": {\n      "command": "npx",\n      "args": [...]\n    }\n  }\n}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<McpProvider>();
              final servers = await provider.importFromJson(controller.text);
              Navigator.pop(context);
              if (servers.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported ${servers.length} server(s)')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to import servers')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.extension_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No MCP servers configured',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Server'),
          ),
        ],
      ),
    );
  }
}

/// MCP 服务器卡片
class _McpServerCard extends StatefulWidget {
  final McpServer server;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _McpServerCard({
    required this.server,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
  });

  @override
  State<_McpServerCard> createState() => _McpServerCardState();
}

class _McpServerCardState extends State<_McpServerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 头部
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 状态图标
                  _StatusIcon(status: widget.server.status),
                  const SizedBox(width: 12),
                  
                  // 名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.server.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1a1a1a),
                          ),
                        ),
                        if (widget.server.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.server.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 测试连接按钮
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 18,
                          color: widget.server.status == McpServerStatus.testing
                              ? const Color(0xFFD97706)
                              : Colors.grey[600],
                        ),
                        onPressed: widget.server.status == McpServerStatus.testing
                            ? null
                            : widget.onTest,
                        tooltip: 'Test Connection',
                      ),
                      
                      // 启用开关
                      Switch(
                        value: widget.server.enabled,
                        onChanged: widget.onToggle,
                        activeColor: const Color(0xFFD97706),
                      ),
                      
                      // 展开/收起图标
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 展开内容
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 传输配置
                  _buildTransportInfo(),
                  
                  const SizedBox(height: 16),
                  
                  // 工具列表
                  if (widget.server.tools != null && widget.server.tools!.isNotEmpty) ...[
                    Text(
                      'Tools (${widget.server.tools!.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.server.tools!.map((tool) => Chip(
                        label: Text(
                          tool.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey.shade100,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportInfo() {
    final transport = widget.server.transport;
    
    if (transport is McpStdioTransport) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Type', value: 'stdio'),
          _InfoRow(label: 'Command', value: transport.command),
          if (transport.args != null && transport.args!.isNotEmpty)
            _InfoRow(label: 'Args', value: transport.args!.join(' ')),
        ],
      );
    } else if (transport is McpSseTransport) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Type', value: 'SSE'),
          _InfoRow(label: 'URL', value: transport.url),
        ],
      );
    } else if (transport is McpHttpTransport) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Type', value: 'HTTP'),
          _InfoRow(label: 'URL', value: transport.url),
        ],
      );
    }
    
    return const SizedBox();
  }
}

/// 状态图标
class _StatusIcon extends StatelessWidget {
  final McpServerStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (status) {
      case McpServerStatus.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case McpServerStatus.disconnected:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
      case McpServerStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      case McpServerStatus.testing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD97706),
          ),
        );
    }
    
    return Icon(icon, size: 20, color: color);
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加/编辑服务器对话框
class _AddEditServerDialog extends StatefulWidget {
  final McpServer? server;
  final Future<void> Function(String name, String? description, McpTransport transport, String? originalJson) onSave;

  const _AddEditServerDialog({
    this.server,
    required this.onSave,
  });

  @override
  State<_AddEditServerDialog> createState() => _AddEditServerDialogState();
}

class _AddEditServerDialogState extends State<_AddEditServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _commandController;
  late TextEditingController _argsController;
  late TextEditingController _urlController;
  
  McpTransportType _transportType = McpTransportType.stdio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '');
    _descriptionController = TextEditingController(text: widget.server?.description ?? '');
    
    if (widget.server != null) {
      final transport = widget.server!.transport;
      if (transport is McpStdioTransport) {
        _transportType = McpTransportType.stdio;
        _commandController = TextEditingController(text: transport.command);
        _argsController = TextEditingController(text: transport.args?.join(' ') ?? '');
        _urlController = TextEditingController();
      } else if (transport is McpSseTransport) {
        _transportType = McpTransportType.sse;
        _commandController = TextEditingController();
        _argsController = TextEditingController();
        _urlController = TextEditingController(text: transport.url);
      } else if (transport is McpHttpTransport) {
        _transportType = McpTransportType.http;
        _commandController = TextEditingController();
        _argsController = TextEditingController();
        _urlController = TextEditingController(text: transport.url);
      } else {
        _commandController = TextEditingController();
        _argsController = TextEditingController();
        _urlController = TextEditingController();
      }
    } else {
      _commandController = TextEditingController();
      _argsController = TextEditingController();
      _urlController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.server == null ? 'Add MCP Server' : 'Edit MCP Server'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., filesystem',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 描述
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief description of the server',
                  ),
                ),
                const SizedBox(height: 16),
                
                // 传输类型
                const Text(
                  'Transport Type',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SegmentedButton<McpTransportType>(
                  segments: const [
                    ButtonSegment(value: McpTransportType.stdio, label: Text('Stdio')),
                    ButtonSegment(value: McpTransportType.sse, label: Text('SSE')),
                    ButtonSegment(value: McpTransportType.http, label: Text('HTTP')),
                  ],
                  selected: {_transportType},
                  onSelectionChanged: (selected) {
                    setState(() => _transportType = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                
                // 根据传输类型显示不同的配置
                if (_transportType == McpTransportType.stdio) ...[
                  TextFormField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      labelText: 'Command',
                      hintText: 'e.g., npx',
                    ),
                    validator: (value) {
                      if (_transportType == McpTransportType.stdio && (value == null || value.isEmpty)) {
                        return 'Please enter a command';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _argsController,
                    decoration: const InputDecoration(
                      labelText: 'Arguments (space-separated)',
                      hintText: 'e.g., -y @modelcontextprotocol/server-filesystem /tmp',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      hintText: _transportType == McpTransportType.sse
                          ? 'e.g., http://localhost:3000/sse'
                          : 'e.g., http://localhost:3000/mcp',
                    ),
                    validator: (value) {
                      if (_transportType != McpTransportType.stdio && (value == null || value.isEmpty)) {
                        return 'Please enter a URL';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      McpTransport transport;
      
      switch (_transportType) {
        case McpTransportType.stdio:
          final args = _argsController.text.trim();
          transport = McpStdioTransport(
            command: _commandController.text.trim(),
            args: args.isEmpty ? null : args.split(' '),
          );
          break;
        case McpTransportType.sse:
          transport = McpSseTransport(url: _urlController.text.trim());
          break;
        case McpTransportType.http:
          transport = McpHttpTransport(url: _urlController.text.trim());
          break;
        case McpTransportType.streamableHttp:
          transport = McpStreamableHttpTransport(url: _urlController.text.trim());
          break;
      }
      
      await widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        transport,
        null,
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

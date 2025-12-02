import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcp_provider.dart';
import '../models/mcp_server.dart';

/// MCP 菜单按钮 - 用于首页输入框
class McpMenuButton extends StatefulWidget {
  final VoidCallback? onManageConnectors;
  
  const McpMenuButton({
    super.key,
    this.onManageConnectors,
  });

  @override
  State<McpMenuButton> createState() => _McpMenuButtonState();
}

class _McpMenuButtonState extends State<McpMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<McpProvider>(
      builder: (context, mcpProvider, _) {
        final enabledCount = mcpProvider.enabledServers.length;
        
        return Tooltip(
          message: 'MCP Connectors',
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: () => _showMcpMenu(context, mcpProvider),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isHovered 
                      ? Colors.grey.shade100 
                      : (enabledCount > 0 
                          ? const Color(0xFFD97706).withOpacity(0.1) 
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.extension,
                        size: 18,
                        color: enabledCount > 0 
                            ? const Color(0xFFD97706) 
                            : Colors.grey[600],
                      ),
                    ),
                    // 启用数量徽章
                    if (enabledCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              enabledCount > 9 ? '9+' : enabledCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMcpMenu(BuildContext context, McpProvider mcpProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 360,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.extension,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MCP Connectors',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // 搜索框
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search connectors...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                  ),
                ),
              ),
              
              // 服务器列表
              Flexible(
                child: Consumer<McpProvider>(
                  builder: (context, provider, _) {
                    if (provider.servers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.extension_off,
                              size: 48,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No connectors configured',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: provider.servers.length,
                      itemBuilder: (context, index) {
                        final server = provider.servers[index];
                        return _McpServerItem(
                          server: server,
                          isDark: isDark,
                          onToggle: (enabled) {
                            provider.toggleServer(server.id, enabled);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              // 底部操作
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onManageConnectors?.call();
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Manage connectors'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MCP 服务器列表项
class _McpServerItem extends StatelessWidget {
  final McpServer server;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const _McpServerItem({
    required this.server,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildStatusIcon(),
        title: Text(
          server.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1a1a1a),
          ),
        ),
        subtitle: server.description != null
            ? Text(
                server.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 工具数量
            if (server.tools != null && server.tools!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${server.tools!.length} tools',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // 启用开关
            Switch(
              value: server.enabled,
              onChanged: onToggle,
              activeColor: const Color(0xFFD97706),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            // 展开箭头
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color color;
    IconData icon;
    
    switch (server.status) {
      case McpServerStatus.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case McpServerStatus.disconnected:
        color = Colors.grey;
        icon = Icons.circle_outlined;
        break;
      case McpServerStatus.error:
        color = Colors.red;
        icon = Icons.error;
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

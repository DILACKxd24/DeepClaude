import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/mcp_server.dart';

class McpProvider extends ChangeNotifier {
  List<McpServer> _servers = [];
  bool _isLoading = false;
  String? _error;
  
  List<McpServer> get servers => _servers;
  List<McpServer> get enabledServers => _servers.where((s) => s.enabled).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  McpProvider() {
    _loadServers();
  }
  
  Future<void> _loadServers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final serversJson = prefs.getString('mcp_servers');
      
      if (serversJson != null) {
        final List<dynamic> decoded = jsonDecode(serversJson);
        _servers = decoded
            .map((json) => McpServer.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // 初始化默认 MCP 服务器
        _servers = _getDefaultServers();
        await _saveServers();
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load MCP servers: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<McpServer> _getDefaultServers() {
    final now = DateTime.now();
    return [
      McpServer(
        id: const Uuid().v4(),
        name: 'filesystem',
        description: 'File system operations MCP server',
        enabled: false,
        transport: McpStdioTransport(
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        ),
        status: McpServerStatus.disconnected,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serversJson = jsonEncode(_servers.map((s) => s.toJson()).toList());
      await prefs.setString('mcp_servers', serversJson);
    } catch (e) {
      print('Failed to save MCP servers: $e');
    }
  }
  
  /// 添加新的 MCP 服务器
  Future<McpServer?> addServer({
    required String name,
    String? description,
    required McpTransport transport,
    bool enabled = false,
    String? originalJson,
  }) async {
    try {
      final now = DateTime.now();
      final server = McpServer(
        id: const Uuid().v4(),
        name: name,
        description: description,
        enabled: enabled,
        transport: transport,
        status: McpServerStatus.disconnected,
        createdAt: now,
        updatedAt: now,
        originalJson: originalJson,
      );
      
      _servers.add(server);
      await _saveServers();
      notifyListeners();
      
      return server;
    } catch (e) {
      _error = 'Failed to add server: $e';
      notifyListeners();
      return null;
    }
  }
  
  /// 更新 MCP 服务器
  Future<bool> updateServer(McpServer server) async {
    try {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index == -1) return false;
      
      _servers[index] = server.copyWith(updatedAt: DateTime.now());
      await _saveServers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update server: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// 删除 MCP 服务器
  Future<bool> deleteServer(String serverId) async {
    try {
      _servers.removeWhere((s) => s.id == serverId);
      await _saveServers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete server: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// 切换服务器启用状态
  Future<bool> toggleServer(String serverId, bool enabled) async {
    try {
      final index = _servers.indexWhere((s) => s.id == serverId);
      if (index == -1) return false;
      
      _servers[index] = _servers[index].copyWith(
        enabled: enabled,
        updatedAt: DateTime.now(),
      );
      await _saveServers();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to toggle server: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// 测试服务器连接
  Future<bool> testConnection(String serverId) async {
    final index = _servers.indexWhere((s) => s.id == serverId);
    if (index == -1) return false;
    
    // 设置测试状态
    _servers[index] = _servers[index].copyWith(
      status: McpServerStatus.testing,
    );
    notifyListeners();
    
    try {
      // TODO: 实现实际的连接测试逻辑
      await Future.delayed(const Duration(seconds: 2));
      
      // 模拟成功连接
      _servers[index] = _servers[index].copyWith(
        status: McpServerStatus.connected,
        lastConnected: DateTime.now(),
      );
      await _saveServers();
      notifyListeners();
      return true;
    } catch (e) {
      _servers[index] = _servers[index].copyWith(
        status: McpServerStatus.error,
      );
      notifyListeners();
      return false;
    }
  }
  
  /// 从 JSON 配置导入服务器
  Future<List<McpServer>> importFromJson(String jsonConfig) async {
    try {
      final Map<String, dynamic> config = jsonDecode(jsonConfig);
      final mcpServers = config['mcpServers'] as Map<String, dynamic>?;
      
      if (mcpServers == null || mcpServers.isEmpty) {
        throw Exception('No MCP servers found in config');
      }
      
      final List<McpServer> importedServers = [];
      final now = DateTime.now();
      
      for (final entry in mcpServers.entries) {
        final name = entry.key;
        final serverConfig = entry.value as Map<String, dynamic>;
        
        McpTransport transport;
        
        if (serverConfig.containsKey('command')) {
          // Stdio transport
          transport = McpStdioTransport(
            command: serverConfig['command'] as String,
            args: (serverConfig['args'] as List<dynamic>?)?.cast<String>(),
            env: (serverConfig['env'] as Map<String, dynamic>?)?.cast<String, String>(),
          );
        } else if (serverConfig.containsKey('url')) {
          final url = serverConfig['url'] as String;
          final headers = (serverConfig['headers'] as Map<String, dynamic>?)?.cast<String, String>();
          
          if (serverConfig['type'] == 'sse') {
            transport = McpSseTransport(url: url, headers: headers);
          } else {
            transport = McpHttpTransport(url: url, headers: headers);
          }
        } else {
          continue; // Skip invalid config
        }
        
        final server = McpServer(
          id: const Uuid().v4(),
          name: name,
          description: serverConfig['description'] as String?,
          enabled: !(serverConfig['disabled'] as bool? ?? false),
          transport: transport,
          status: McpServerStatus.disconnected,
          createdAt: now,
          updatedAt: now,
          originalJson: jsonEncode({name: serverConfig}),
        );
        
        _servers.add(server);
        importedServers.add(server);
      }
      
      await _saveServers();
      notifyListeners();
      
      return importedServers;
    } catch (e) {
      _error = 'Failed to import servers: $e';
      notifyListeners();
      return [];
    }
  }
  
  /// 导出服务器配置为 JSON
  String exportToJson() {
    final mcpServers = <String, dynamic>{};
    
    for (final server in _servers) {
      final config = <String, dynamic>{};
      
      if (server.transport is McpStdioTransport) {
        final t = server.transport as McpStdioTransport;
        config['command'] = t.command;
        if (t.args != null) config['args'] = t.args;
        if (t.env != null) config['env'] = t.env;
      } else if (server.transport is McpSseTransport) {
        final t = server.transport as McpSseTransport;
        config['url'] = t.url;
        config['type'] = 'sse';
        if (t.headers != null) config['headers'] = t.headers;
      } else if (server.transport is McpHttpTransport) {
        final t = server.transport as McpHttpTransport;
        config['url'] = t.url;
        if (t.headers != null) config['headers'] = t.headers;
      }
      
      config['disabled'] = !server.enabled;
      if (server.description != null) config['description'] = server.description;
      
      mcpServers[server.name] = config;
    }
    
    return const JsonEncoder.withIndent('  ').convert({'mcpServers': mcpServers});
  }
  
  /// 刷新所有服务器状态
  Future<void> refreshAll() async {
    for (final server in _servers) {
      if (server.enabled) {
        await testConnection(server.id);
      }
    }
  }
}

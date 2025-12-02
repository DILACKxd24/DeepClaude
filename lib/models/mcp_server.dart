import 'dart:convert';

/// MCP 传输类型
enum McpTransportType { stdio, sse, http, streamableHttp }

/// MCP 服务器状态
enum McpServerStatus { connected, disconnected, error, testing }

/// MCP 传输配置基类
abstract class McpTransport {
  McpTransportType get type;
  Map<String, dynamic> toJson();
  
  factory McpTransport.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'stdio':
        return McpStdioTransport.fromJson(json);
      case 'sse':
        return McpSseTransport.fromJson(json);
      case 'http':
        return McpHttpTransport.fromJson(json);
      case 'streamable_http':
        return McpStreamableHttpTransport.fromJson(json);
      default:
        throw ArgumentError('Unknown transport type: $type');
    }
  }
}

/// Stdio 传输配置
class McpStdioTransport implements McpTransport {
  @override
  McpTransportType get type => McpTransportType.stdio;
  
  final String command;
  final List<String>? args;
  final Map<String, String>? env;
  
  McpStdioTransport({
    required this.command,
    this.args,
    this.env,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'stdio',
    'command': command,
    if (args != null) 'args': args,
    if (env != null) 'env': env,
  };
  
  factory McpStdioTransport.fromJson(Map<String, dynamic> json) {
    return McpStdioTransport(
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>?)?.cast<String>(),
      env: (json['env'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

/// SSE 传输配置
class McpSseTransport implements McpTransport {
  @override
  McpTransportType get type => McpTransportType.sse;
  
  final String url;
  final Map<String, String>? headers;
  
  McpSseTransport({
    required this.url,
    this.headers,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'sse',
    'url': url,
    if (headers != null) 'headers': headers,
  };
  
  factory McpSseTransport.fromJson(Map<String, dynamic> json) {
    return McpSseTransport(
      url: json['url'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

/// HTTP 传输配置
class McpHttpTransport implements McpTransport {
  @override
  McpTransportType get type => McpTransportType.http;
  
  final String url;
  final Map<String, String>? headers;
  
  McpHttpTransport({
    required this.url,
    this.headers,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'http',
    'url': url,
    if (headers != null) 'headers': headers,
  };
  
  factory McpHttpTransport.fromJson(Map<String, dynamic> json) {
    return McpHttpTransport(
      url: json['url'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

/// Streamable HTTP 传输配置
class McpStreamableHttpTransport implements McpTransport {
  @override
  McpTransportType get type => McpTransportType.streamableHttp;
  
  final String url;
  final Map<String, String>? headers;
  
  McpStreamableHttpTransport({
    required this.url,
    this.headers,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'streamable_http',
    'url': url,
    if (headers != null) 'headers': headers,
  };
  
  factory McpStreamableHttpTransport.fromJson(Map<String, dynamic> json) {
    return McpStreamableHttpTransport(
      url: json['url'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

/// MCP 工具定义
class McpTool {
  final String name;
  final String? description;
  
  McpTool({
    required this.name,
    this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
  };
  
  factory McpTool.fromJson(Map<String, dynamic> json) {
    return McpTool(
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

/// MCP 服务器配置
class McpServer {
  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final McpTransport transport;
  final List<McpTool>? tools;
  final McpServerStatus status;
  final DateTime? lastConnected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? originalJson;
  
  McpServer({
    required this.id,
    required this.name,
    this.description,
    this.enabled = false,
    required this.transport,
    this.tools,
    this.status = McpServerStatus.disconnected,
    this.lastConnected,
    required this.createdAt,
    required this.updatedAt,
    this.originalJson,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'enabled': enabled,
    'transport': transport.toJson(),
    if (tools != null) 'tools': tools!.map((t) => t.toJson()).toList(),
    'status': status.name,
    if (lastConnected != null) 'lastConnected': lastConnected!.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    if (originalJson != null) 'originalJson': originalJson,
  };
  
  factory McpServer.fromJson(Map<String, dynamic> json) {
    return McpServer(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool? ?? false,
      transport: McpTransport.fromJson(json['transport'] as Map<String, dynamic>),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => McpTool.fromJson(t as Map<String, dynamic>))
          .toList(),
      status: McpServerStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => McpServerStatus.disconnected,
      ),
      lastConnected: json['lastConnected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastConnected'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      originalJson: json['originalJson'] as String?,
    );
  }
  
  McpServer copyWith({
    String? id,
    String? name,
    String? description,
    bool? enabled,
    McpTransport? transport,
    List<McpTool>? tools,
    McpServerStatus? status,
    DateTime? lastConnected,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? originalJson,
  }) {
    return McpServer(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      transport: transport ?? this.transport,
      tools: tools ?? this.tools,
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      originalJson: originalJson ?? this.originalJson,
    );
  }
}

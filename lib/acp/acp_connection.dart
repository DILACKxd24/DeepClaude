import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'acp_types.dart';

/// ACP 连接状态
enum AcpConnectionState {
  disconnected,
  connecting,
  connected,
  authenticated,
  sessionActive,
  error,
}

/// 权限请求选项
class PermissionOption {
  final String id;
  final String name;
  final String kind; // allow_once, allow_always, reject_once, reject_always

  PermissionOption({
    required this.id,
    required this.name,
    required this.kind,
  });

  factory PermissionOption.fromJson(Map<String, dynamic> json) {
    return PermissionOption(
      id: json['optionId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['label'] ?? '',
      kind: json['kind'] ?? 'allow_once',
    );
  }

  bool get isAllow => kind.contains('allow');
}

/// 权限请求
class PermissionRequest {
  final String sessionId;
  final String toolCallId;
  final String title;
  final String? description;
  final List<PermissionOption> options;
  final ToolCallData? toolCall;

  PermissionRequest({
    required this.sessionId,
    required this.toolCallId,
    required this.title,
    this.description,
    required this.options,
    this.toolCall,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    final toolCallJson = json['toolCall'] as Map<String, dynamic>?;
    final toolCallId = toolCallJson?['toolCallId'] ?? '';

    String title = toolCallJson?['title'] ?? 'Permission Request';
    String? description;

    // 从 rawInput 获取描述
    if (toolCallJson?['rawInput'] != null) {
      final rawInput = toolCallJson!['rawInput'] as Map<String, dynamic>;
      description = rawInput['command'] ?? rawInput['description'];
    }

    final optionsList = (json['options'] as List?)
            ?.map((o) => PermissionOption.fromJson(o))
            .toList() ??
        [
          PermissionOption(id: 'allow_once', name: 'Allow', kind: 'allow_once'),
          PermissionOption(id: 'reject_once', name: 'Reject', kind: 'reject_once'),
        ];

    return PermissionRequest(
      sessionId: json['sessionId'] ?? '',
      toolCallId: toolCallId,
      title: title,
      description: description,
      options: optionsList,
      toolCall: toolCallJson != null ? ToolCallData.fromJson(toolCallJson) : null,
    );
  }
}

/// ACP 连接管理器
class AcpConnection {
  Process? _process;
  String? _sessionId;
  int _nextRequestId = 0;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  final Map<String, Completer<String>> _permissionCompleters = {};
  String _buffer = '';

  AcpConnectionState _state = AcpConnectionState.disconnected;
  AcpConnectionState get state => _state;

  String? _workingDir;
  String? get workingDir => _workingDir;

  // 事件回调
  Function(AcpConnectionState)? onStateChanged;
  Function(String content, {bool isThinking, String? messageId})? onContentReceived;
  Function(ToolCallData)? onToolCall;
  Function(PermissionRequest)? onPermissionRequest;
  Function(String)? onError;
  Function()? onEndTurn;
  Function(List<PlanEntry>)? onPlanUpdate;
  Function(List<AvailableCommand>)? onCommandsUpdate;

  String? _currentMessageId;

  /// 连接到 DeepClaude ACP
  Future<void> connect({String? workingDir}) async {
    if (_process != null) {
      await disconnect();
    }

    _workingDir = workingDir ?? Directory.current.path;
    _updateState(AcpConnectionState.connecting);

    try {
      // 使用 npx 启动 claude-code-acp (Zed 提供的 ACP 桥接器)
      final isWindows = Platform.isWindows;
      final command = isWindows ? 'npx.cmd' : 'npx';
      
      // 使用 @zed-industries/claude-code-acp 包
      final args = ['@zed-industries/claude-code-acp'];

      print('[ACP] Starting: $command ${args.join(' ')}');
      print('[ACP] Working directory: $_workingDir');

      _process = await Process.start(
        command,
        args,
        workingDirectory: _workingDir,
        environment: {
          ...Platform.environment,
          'FORCE_COLOR': '0', // 禁用颜色输出
        },
      );

      // 监听 stdout
      _process!.stdout.transform(utf8.decoder).listen(
        _handleStdout,
        onError: (e) => print('[ACP STDOUT ERROR]: $e'),
      );

      // 监听 stderr
      _process!.stderr.transform(utf8.decoder).listen(
        (data) => print('[ACP STDERR]: $data'),
        onError: (e) => print('[ACP STDERR ERROR]: $e'),
      );

      // 监听进程退出
      _process!.exitCode.then((code) {
        print('[ACP] Process exited with code: $code');
        if (_state != AcpConnectionState.disconnected) {
          _updateState(AcpConnectionState.disconnected);
          onError?.call('DeepClaude 进程已退出 (code: $code)');
        }
      });

      // 等待进程启动
      await Future.delayed(const Duration(milliseconds: 500));

      if (_process == null) {
        throw Exception('Failed to start DeepClaude process');
      }

      print('[ACP] Process started with PID: ${_process!.pid}');

      // 初始化协议
      print('[ACP] Sending initialize request...');
      await _initialize();
      print('[ACP] Initialize completed');
      _updateState(AcpConnectionState.connected);
    } catch (e) {
      print('[ACP] Connection error: $e');
      _updateState(AcpConnectionState.error);
      onError?.call('连接失败: $e');
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _process?.kill();
    _process = null;
    _sessionId = null;
    _pendingRequests.clear();
    _permissionCompleters.clear();
    _buffer = '';
    _currentMessageId = null;
    _updateState(AcpConnectionState.disconnected);
  }

  /// 创建新会话
  Future<void> newSession() async {
    if (_state != AcpConnectionState.connected &&
        _state != AcpConnectionState.authenticated) {
      throw Exception('Not connected');
    }

    print('[ACP] Creating new session...');

    final response = await _sendRequest('session/new', {
      'cwd': _workingDir,
      'mcpServers': [],
    });

    _sessionId = response['sessionId'];
    print('[ACP] Session created: $_sessionId');
    _updateState(AcpConnectionState.sessionActive);
  }

  /// 发送消息
  Future<void> sendPrompt(String prompt) async {
    if (_sessionId == null) {
      throw Exception('No active session');
    }

    // 重置消息 ID，开始新的响应
    _currentMessageId = _generateId();

    print('[ACP] Sending prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');

    await _sendRequest('session/prompt', {
      'sessionId': _sessionId,
      'prompt': [
        {'type': 'text', 'text': prompt}
      ],
    });
  }

  /// 初始化协议
  Future<void> _initialize() async {
    print('[ACP] Initializing protocol...');

    await _sendRequest('initialize', {
      'protocolVersion': 1,
      'clientCapabilities': {
        'fs': {
          'readTextFile': true,
          'writeTextFile': true,
        },
      },
    });

    print('[ACP] Protocol initialized');
  }

  /// 发送请求
  Future<dynamic> _sendRequest(String method, Map<String, dynamic>? params) {
    final id = _nextRequestId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final message = {
      'jsonrpc': jsonRpcVersion,
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };

    _sendMessage(message);

    // 设置超时
    final timeout = method == 'session/prompt' ? 180 : 60;
    Future.delayed(Duration(seconds: timeout), () {
      if (_pendingRequests.containsKey(id)) {
        _pendingRequests.remove(id);
        completer.completeError(TimeoutException('Request timeout: $method'));
      }
    });

    return completer.future;
  }

  /// 发送消息到进程
  void _sendMessage(Map<String, dynamic> message) {
    if (_process == null) return;

    final json = jsonEncode(message);
    final lineEnding = Platform.isWindows ? '\r\n' : '\n';
    
    print('[ACP TX]: ${json.substring(0, json.length.clamp(0, 200))}...');
    _process!.stdin.write('$json$lineEnding');
  }

  /// 发送响应
  void _sendResponse(int id, dynamic result, {Map<String, dynamic>? error}) {
    if (_process == null) return;

    final response = <String, dynamic>{
      'jsonrpc': jsonRpcVersion,
      'id': id,
    };

    if (error != null) {
      response['error'] = error;
    } else {
      response['result'] = result;
    }

    final json = jsonEncode(response);
    final lineEnding = Platform.isWindows ? '\r\n' : '\n';
    _process!.stdin.write('$json$lineEnding');
  }

  /// 处理 stdout 数据
  void _handleStdout(String data) {
    print('[ACP RAW STDOUT]: $data');
    _buffer += data;
    final lines = _buffer.split('\n');
    _buffer = lines.removeLast();

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line);
        print('[ACP RX]: ${line.substring(0, line.length.clamp(0, 200))}...');
        _handleMessage(json);
      } catch (e) {
        // 忽略非 JSON 消息
        print('[ACP] Non-JSON: $line');
      }
    }
  }

  /// 处理消息
  void _handleMessage(Map<String, dynamic> message) {
    // 如果是请求（有 method）
    if (message.containsKey('method')) {
      _handleIncomingRequest(message);
      return;
    }

    // 如果是响应（有 id 且在 pending 中）
    if (message.containsKey('id') && _pendingRequests.containsKey(message['id'])) {
      final completer = _pendingRequests.remove(message['id']);
      if (message.containsKey('error')) {
        final errorMsg = message['error']?['message'] ?? 'Unknown error';
        final errorCode = message['error']?['code'];
        
        // 特殊处理认证错误
        if (errorMsg.contains('Authentication required') || errorCode == -32000) {
          onError?.call('需要认证：请在终端运行 "claude login" 登录后重试');
          _updateState(AcpConnectionState.error);
        }
        
        completer?.completeError(Exception(errorMsg));
      } else {
        // 检查是否是 end_turn
        final result = message['result'];
        if (result is Map && result['stopReason'] == 'end_turn') {
          onEndTurn?.call();
        }
        completer?.complete(result);
      }
    }
  }

  /// 处理传入的请求
  Future<void> _handleIncomingRequest(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'] as Map<String, dynamic>?;
    final id = message['id'] as int?;

    try {
      dynamic result;

      switch (method) {
        case 'session/update':
          _handleSessionUpdate(params);
          break;

        case 'session/request_permission':
          result = await _handlePermissionRequest(message);
          break;

        case 'fs/read_text_file':
          result = await _handleReadFile(params);
          break;

        case 'fs/write_text_file':
          result = await _handleWriteFile(params);
          break;

        default:
          print('[ACP] Unknown method: $method');
      }

      // 如果是请求（有 id），发送响应
      if (id != null) {
        _sendResponse(id, result);
      }
    } catch (e) {
      if (id != null) {
        _sendResponse(id, null, error: {
          'code': -32603,
          'message': e.toString(),
        });
      }
    }
  }

  /// 处理会话更新
  void _handleSessionUpdate(Map<String, dynamic>? params) {
    if (params == null) return;

    final update = params['update'] as Map<String, dynamic>?;
    if (update == null) return;

    final sessionUpdate = update['sessionUpdate'] as String?;

    switch (sessionUpdate) {
      case 'agent_message_chunk':
        final content = update['content'] as Map<String, dynamic>?;
        if (content != null && content['text'] != null) {
          onContentReceived?.call(
            content['text'],
            isThinking: false,
            messageId: _currentMessageId,
          );
        }
        break;

      case 'agent_thought_chunk':
        final content = update['content'] as Map<String, dynamic>?;
        if (content != null && content['text'] != null) {
          onContentReceived?.call(
            content['text'],
            isThinking: true,
            messageId: _currentMessageId,
          );
        }
        // 思考结束后重置消息 ID
        _currentMessageId = _generateId();
        break;

      case 'tool_call':
        final toolCallData = ToolCallData.fromJson(update);
        onToolCall?.call(toolCallData);
        // 工具调用后重置消息 ID
        _currentMessageId = _generateId();
        break;

      case 'tool_call_update':
        final toolCallData = ToolCallData.fromJson(update);
        onToolCall?.call(toolCallData);
        break;

      case 'plan':
        final entries = (update['entries'] as List?)
                ?.map((e) => PlanEntry.fromJson(e))
                .toList() ??
            [];
        onPlanUpdate?.call(entries);
        break;

      case 'available_commands_update':
        final commands = (update['availableCommands'] as List?)
                ?.map((c) => AvailableCommand.fromJson(c))
                .toList() ??
            [];
        onCommandsUpdate?.call(commands);
        break;
    }
  }

  /// 处理权限请求
  Future<Map<String, dynamic>> _handlePermissionRequest(Map<String, dynamic> message) async {
    final params = message['params'] as Map<String, dynamic>?;
    if (params == null) {
      return {'outcome': {'outcome': 'rejected', 'optionId': 'reject_once'}};
    }

    final request = PermissionRequest.fromJson(params);

    // 创建 Completer 等待用户响应
    final completer = Completer<String>();
    _permissionCompleters[request.toolCallId] = completer;

    // 通知 UI 显示权限请求
    onPermissionRequest?.call(request);

    try {
      final optionId = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => 'reject_once',
      );

      final outcome = optionId.contains('reject') ? 'rejected' : 'selected';

      return {
        'outcome': {
          'outcome': outcome,
          'optionId': optionId,
        }
      };
    } catch (e) {
      return {'outcome': {'outcome': 'rejected', 'optionId': 'reject_once'}};
    } finally {
      _permissionCompleters.remove(request.toolCallId);
    }
  }

  /// 用户响应权限请求
  void respondPermission(String toolCallId, String optionId) {
    final completer = _permissionCompleters.remove(toolCallId);
    completer?.complete(optionId);
  }

  /// 处理文件读取
  Future<Map<String, dynamic>> _handleReadFile(Map<String, dynamic>? params) async {
    final path = params?['path'] as String?;
    if (path == null) {
      throw Exception('Missing path parameter');
    }

    final file = File(_resolvePath(path));
    final content = await file.readAsString();
    return {'content': content};
  }

  /// 处理文件写入
  Future<Map<String, dynamic>?> _handleWriteFile(Map<String, dynamic>? params) async {
    final path = params?['path'] as String?;
    final content = params?['content'] as String?;
    if (path == null || content == null) {
      throw Exception('Missing path or content parameter');
    }

    final file = File(_resolvePath(path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return null;
  }

  /// 解析路径
  String _resolvePath(String path) {
    if (path.startsWith('/') || path.contains(':')) {
      return path;
    }
    return '${_workingDir ?? Directory.current.path}/$path';
  }

  void _updateState(AcpConnectionState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isConnected =>
      _state == AcpConnectionState.connected ||
      _state == AcpConnectionState.authenticated ||
      _state == AcpConnectionState.sessionActive;

  bool get hasActiveSession => _sessionId != null;
}

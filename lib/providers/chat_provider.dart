import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../acp/acp_connection.dart';
import '../acp/acp_types.dart';
import '../services/storage_service.dart';
import '../services/workspace_service.dart';
import 'settings_provider.dart';

/// 消息类型
enum MessageType {
  user,
  assistant,
  system,
  thinking,
  toolCall,
  permission,
  plan,
}

/// 文件附件
class FileAttachment {
  final String name;
  final String path;
  final String content; // 文件内容（文本文件）
  final int size;
  final String mimeType;

  FileAttachment({
    required this.name,
    required this.path,
    required this.content,
    required this.size,
    this.mimeType = 'text/plain',
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      content: json['content'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'] ?? 'text/plain',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'content': content,
      'size': size,
      'mimeType': mimeType,
    };
  }
}

/// 聊天消息
class ChatMessage {
  final String id;
  final MessageType type;
  String content;
  final DateTime timestamp;
  final int sequence; // 消息序列号，用于排序
  bool isStreaming;
  final PermissionRequest? permissionRequest;
  final ToolCallData? toolCallData;
  final List<PlanEntry>? planEntries;
  final List<FileAttachment>? attachments; // 附件列表

  ChatMessage({
    String? id,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.sequence = 0,
    this.isStreaming = false,
    this.permissionRequest,
    this.toolCallData,
    this.planEntries,
    this.attachments,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    ToolCallData? toolCallData,
    int? sequence,
    List<FileAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id,
      type: type,
      content: content ?? this.content,
      timestamp: timestamp,
      sequence: sequence ?? this.sequence,
      isStreaming: isStreaming ?? this.isStreaming,
      permissionRequest: permissionRequest,
      toolCallData: toolCallData ?? this.toolCallData,
      planEntries: planEntries,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// 会话
class Conversation {
  final String id;
  final String name;
  final String workingDir;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  Conversation({
    String? id,
    required this.name,
    required this.workingDir,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 获取显示标题（用户第一条消息，或默认名称）
  String get displayTitle {
    // 查找第一条用户消息
    final userMessages = messages.where((m) => m.type == MessageType.user).toList();
    if (userMessages.isNotEmpty) {
      final firstUserMessage = userMessages.first.content;
      // 截取前30个字符作为标题
      if (firstUserMessage.length > 30) {
        return '${firstUserMessage.substring(0, 30)}...';
      }
      return firstUserMessage;
    }
    // 没有用户消息时显示 "New Chat"
    return 'New Chat';
  }

  Conversation copyWith({List<ChatMessage>? messages}) {
    return Conversation(
      id: id,
      name: name,
      workingDir: workingDir,
      messages: messages ?? this.messages,
      createdAt: createdAt,
    );
  }
}

/// 聊天状态管理
class ChatProvider extends ChangeNotifier {
  final AcpConnection _connection = AcpConnection();
  final List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _error;
  SettingsProvider? _settings;
  final StorageService _storage = StorageService.instance;
  bool _initialized = false;

  // 用于流式消息的追踪
  String? _currentStreamingMessageId;
  final Map<String, ChatMessage> _toolCallMessages = {};
  
  // 消息序列号计数器，确保消息按到达顺序排列
  int _messageSequence = 0;
  
  // 当前 Plan 消息的 ID（用于更新而非创建新消息）
  String? _currentPlanMessageId;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AcpConnectionState get connectionState => _connection.state;
  bool get isConnected => _connection.isConnected;

  ChatProvider() {
    _setupConnectionCallbacks();
    _loadHistory();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final savedConversations = await _storage.loadConversations();
      int maxSequence = 0;
      
      for (final conv in savedConversations) {
        final messages = await _storage.loadMessages(conv.id);
        // 找出最大序列号
        for (final msg in messages) {
          if (msg.sequence > maxSequence) {
            maxSequence = msg.sequence;
          }
        }
        _conversations.add(conv.copyWith(messages: messages));
      }
      
      // 设置序列号计数器为最大值+1
      _messageSequence = maxSequence + 1;
      notifyListeners();
    } catch (e) {
      print('加载历史记录失败: $e');
    }
  }

  /// 保存当前会话
  Future<void> _saveCurrentConversation() async {
    if (_currentConversation == null) return;

    try {
      await _storage.saveConversations(_conversations);
      await _storage.saveMessages(
        _currentConversation!.id,
        _currentConversation!.messages,
      );
    } catch (e) {
      print('保存会话失败: $e');
    }
  }

  void _setupConnectionCallbacks() {
    _connection.onStateChanged = (state) {
      notifyListeners();
    };

    _connection.onContentReceived = (content, {bool isThinking = false, String? messageId}) {
      _handleContentReceived(content, isThinking: isThinking, messageId: messageId);
    };

    _connection.onToolCall = (toolCallData) {
      _handleToolCall(toolCallData);
    };

    _connection.onPermissionRequest = (request) {
      _handlePermissionRequest(request);
    };

    _connection.onError = (error) {
      _error = error;
      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '❌ $error',
      ));
      notifyListeners();
    };

    _connection.onEndTurn = () {
      _finalizeCurrentMessage();
      _isLoading = false;
      notifyListeners();
    };

    _connection.onPlanUpdate = (entries) {
      _handlePlanUpdate(entries);
    };

    _connection.onCommandsUpdate = (commands) {
      // 可以在这里处理可用命令更新
      print('Available commands: ${commands.map((c) => c.name).join(', ')}');
    };
  }

  /// 创建新会话（自动在 .deepclaude/sessions 下创建工作目录）
  Future<void> createNewConversation() async {
    print('[ChatProvider] Creating new conversation with auto-generated directory');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 自动创建会话工作目录
      final workingDir = await WorkspaceService.instance.createSessionWorkingDir();
      print('[ChatProvider] Created session directory: $workingDir');

      await _connectAndCreateSession(workingDir);
    } catch (e) {
      _error = '创建会话失败: $e';
      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '❌ 连接失败: $e\n\n请确保已安装 Claude Code CLI:\nnpm install -g @anthropics/claude-code',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建新会话（使用指定的工作目录）
  Future<void> createConversation(String workingDir) async {
    print('[ChatProvider] Creating conversation for: $workingDir');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _connectAndCreateSession(workingDir);
    } catch (e) {
      _error = '创建会话失败: $e';
      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '❌ 连接失败: $e\n\n请确保已安装 Claude Code CLI:\nnpm install -g @anthropics/claude-code',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 连接并创建会话的内部方法
  Future<void> _connectAndCreateSession(String workingDir) async {
    // 连接到 ACP
    print('[ChatProvider] Connecting to ACP...');
    await _connection.connect(workingDir: workingDir);
    print('[ChatProvider] Connected, creating session...');

    // 创建新会话
    await _connection.newSession();
    print('[ChatProvider] Session created');

    // 创建会话对象
    final name = workingDir.split('/').last;
    final conversation = Conversation(
      name: name,
      workingDir: workingDir,
    );

    _conversations.add(conversation);
    _currentConversation = conversation;

    // 添加系统消息
    _addMessage(ChatMessage(
      type: MessageType.system,
      content: '✅ 已连接到 Claude Code\n📁 工作目录: $workingDir',
    ));

    await _saveCurrentConversation();
  }

  /// 发送消息
  Future<void> sendMessage(String content, {List<FileAttachment>? attachments}) async {
    if (_currentConversation == null || !_connection.hasActiveSession) {
      _error = '请先创建会话';
      notifyListeners();
      return;
    }

    // 重置当前回合的状态
    _currentPlanMessageId = null;
    _toolCallMessages.clear();

    // 构建包含附件的消息内容
    String fullContent = content;
    if (attachments != null && attachments.isNotEmpty) {
      final attachmentTexts = attachments.map((a) {
        return '📎 **${a.name}** (${_formatFileSize(a.size)})\n```\n${a.content}\n```';
      }).join('\n\n');
      fullContent = '$content\n\n$attachmentTexts';
    }

    // 添加用户消息
    _addMessage(ChatMessage(
      type: MessageType.user,
      content: content,
      attachments: attachments,
    ));

    // 创建助手消息占位
    final assistantMessageId = const Uuid().v4();
    _currentStreamingMessageId = assistantMessageId;
    _addMessage(ChatMessage(
      id: assistantMessageId,
      type: MessageType.assistant,
      content: '',
      isStreaming: true,
    ));

    _isLoading = true;
    notifyListeners();

    try {
      // 发送包含文件内容的完整消息
      await _connection.sendPrompt(fullContent);
    } catch (e) {
      _error = '发送失败: $e';
      _finalizeCurrentMessage();
      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '❌ 发送失败: $e',
      ));
    }

    notifyListeners();
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 处理接收到的内容
  void _handleContentReceived(String content, {bool isThinking = false, String? messageId}) {
    if (_currentConversation == null) return;

    if (isThinking) {
      // 思考消息 - 不创建新消息，只是打印日志
      print('[ChatProvider] Thinking: $content');
    } else {
      // 助手消息 - 追加到当前流式消息或创建新消息
      final messages = _currentConversation!.messages;
      
      // 找到当前流式消息
      final streamingIndex = messages.lastIndexWhere(
        (m) => m.type == MessageType.assistant && m.isStreaming,
      );

      if (streamingIndex >= 0) {
        // 追加内容（不改变序列号）
        messages[streamingIndex].content += content;
        notifyListeners();
      } else {
        // 没有流式消息，创建新的助手消息
        // 这通常发生在工具调用完成后继续输出
        final assistantMessageId = const Uuid().v4();
        _currentStreamingMessageId = assistantMessageId;
        _addMessage(ChatMessage(
          id: assistantMessageId,
          type: MessageType.assistant,
          content: content,
          isStreaming: true,
        ));
      }
    }
  }

  /// 处理工具调用
  void _handleToolCall(ToolCallData toolCallData) {
    if (_currentConversation == null) return;

    final existingMessage = _toolCallMessages[toolCallData.toolCallId];

    if (existingMessage != null) {
      // 更新现有的工具调用消息（保持原有序列号）
      final messages = _currentConversation!.messages;
      final index = messages.indexWhere((m) => m.id == existingMessage.id);
      if (index >= 0) {
        messages[index] = existingMessage.copyWith(
          toolCallData: toolCallData,
          content: _formatToolCallContent(toolCallData),
          sequence: existingMessage.sequence, // 保持原有序列号
        );
        // 更新缓存
        _toolCallMessages[toolCallData.toolCallId] = messages[index];
        notifyListeners();
        // 保存工具调用状态更新
        _saveCurrentConversation();
      }
    } else {
      // 新的工具调用 - 先完成当前流式消息
      _finalizeCurrentMessage();
      
      // 创建新的工具调用消息
      final sequence = _messageSequence++;
      final message = ChatMessage(
        type: MessageType.toolCall,
        content: _formatToolCallContent(toolCallData),
        toolCallData: toolCallData,
        sequence: sequence,
      );
      _toolCallMessages[toolCallData.toolCallId] = message;
      _currentConversation!.messages.add(message);
      _currentConversation!.messages.sort((a, b) => a.sequence.compareTo(b.sequence));
      notifyListeners();
      // 保存新的工具调用
      _saveCurrentConversation();
    }
  }

  String _formatToolCallContent(ToolCallData data) {
    final statusIcon = switch (data.status) {
      ToolCallStatus.pending => '⏳',
      ToolCallStatus.inProgress => '🔄',
      ToolCallStatus.completed => '✅',
      ToolCallStatus.failed => '❌',
    };

    final kindIcon = switch (data.kind) {
      ToolCallKind.read => '📖',
      ToolCallKind.edit => '✏️',
      ToolCallKind.execute => '⚡',
    };

    String result = '$statusIcon $kindIcon ${data.title}';

    // 添加位置信息
    if (data.locations.isNotEmpty) {
      result += '\n📍 ${data.locations.join(', ')}';
    }

    // 添加内容预览
    for (final content in data.content) {
      if (content.type == 'diff' && content.path != null) {
        result += '\n📝 ${content.path}';
      } else if (content.text != null && content.text!.isNotEmpty) {
        final preview = content.text!.length > 100
            ? '${content.text!.substring(0, 100)}...'
            : content.text!;
        result += '\n$preview';
      }
    }

    return result;
  }

  /// 处理计划更新
  void _handlePlanUpdate(List<PlanEntry> entries) {
    if (entries.isEmpty) return;
    if (_currentConversation == null) return;

    final content = entries.map((e) {
      final statusIcon = switch (e.status) {
        'completed' => '✅',
        'in_progress' => '🔄',
        _ => '⏳',
      };
      final priority = e.priority != null ? ' [${e.priority!.toUpperCase()}]' : '';
      return '$statusIcon ${e.content}$priority';
    }).join('\n');

    // 查找现有的 Plan 消息并更新
    if (_currentPlanMessageId != null) {
      final messages = _currentConversation!.messages;
      final index = messages.indexWhere((m) => m.id == _currentPlanMessageId);
      if (index >= 0) {
        // 更新现有 Plan 消息（保持原有序列号）
        final existingMsg = messages[index];
        messages[index] = ChatMessage(
          id: existingMsg.id,
          type: MessageType.plan,
          content: '📋 Plan\n\n$content',
          timestamp: existingMsg.timestamp,
          sequence: existingMsg.sequence,
          planEntries: entries,
        );
        notifyListeners();
        // 保存计划更新
        _saveCurrentConversation();
        return;
      }
    }

    // 新的 Plan - 先完成当前流式消息
    _finalizeCurrentMessage();

    // 创建新的 Plan 消息
    final planId = const Uuid().v4();
    _currentPlanMessageId = planId;
    _addMessage(ChatMessage(
      id: planId,
      type: MessageType.plan,
      content: '📋 Plan\n\n$content',
      planEntries: entries,
    ));
    // 保存新的计划
    _saveCurrentConversation();
  }

  /// 处理权限请求
  void _handlePermissionRequest(PermissionRequest request) {
    // 先完成当前流式消息
    _finalizeCurrentMessage();

    _addMessage(ChatMessage(
      type: MessageType.permission,
      content: request.title,
      permissionRequest: request,
    ));
  }

  /// 响应权限请求
  void respondToPermission(String toolCallId, String optionId) {
    _connection.respondPermission(toolCallId, optionId);

    // 更新消息状态
    if (_currentConversation != null) {
      final messages = _currentConversation!.messages;
      final index = messages.indexWhere(
        (m) =>
            m.type == MessageType.permission &&
            m.permissionRequest?.toolCallId == toolCallId,
      );
      if (index >= 0) {
        final msg = messages[index];
        final isAllowed = optionId.contains('allow');
        messages[index] = ChatMessage(
          id: msg.id,
          type: MessageType.system,
          content: '${msg.content} - ${isAllowed ? '✅ 已允许' : '❌ 已拒绝'}',
          timestamp: msg.timestamp,
        );
        notifyListeners();
        _saveCurrentConversation();
      }
    }
  }

  /// 完成当前消息
  void _finalizeCurrentMessage() {
    if (_currentConversation == null) return;

    final messages = _currentConversation!.messages;
    final lastIndex = messages.lastIndexWhere(
      (m) => m.type == MessageType.assistant && m.isStreaming,
    );

    if (lastIndex >= 0) {
      messages[lastIndex].isStreaming = false;
      _currentStreamingMessageId = null;
      notifyListeners();
      _saveCurrentConversation();
    }
  }

  /// 添加消息
  void _addMessage(ChatMessage message) {
    if (_currentConversation == null) return;
    
    // 分配序列号
    final messageWithSequence = ChatMessage(
      id: message.id,
      type: message.type,
      content: message.content,
      timestamp: message.timestamp,
      sequence: _messageSequence++,
      isStreaming: message.isStreaming,
      permissionRequest: message.permissionRequest,
      toolCallData: message.toolCallData,
      planEntries: message.planEntries,
      attachments: message.attachments,
    );
    
    _currentConversation!.messages.add(messageWithSequence);
    // 按序列号排序，确保消息按到达顺序显示
    _currentConversation!.messages.sort((a, b) => a.sequence.compareTo(b.sequence));
    notifyListeners();
  }

  /// 切换会话
  void switchConversation(String id) {
    _currentConversation = _conversations.firstWhere((c) => c.id == id);
    notifyListeners();
  }

  /// 清除当前会话（回到首页）
  void clearCurrentConversation() {
    _currentConversation = null;
    notifyListeners();
  }

  /// 重新连接会话
  Future<void> reconnectConversation(String id) async {
    final conversation = _conversations.firstWhere((c) => c.id == id);
    _currentConversation = conversation;

    _isLoading = true;
    notifyListeners();

    try {
      await _connection.connect(workingDir: conversation.workingDir);
      await _connection.newSession();

      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '✅ 已重新连接',
      ));
    } catch (e) {
      _error = '重新连接失败: $e';
      _addMessage(ChatMessage(
        type: MessageType.system,
        content: '❌ 重新连接失败: $e',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 关闭会话
  Future<void> closeConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    if (_currentConversation?.id == id) {
      _currentConversation = _conversations.isNotEmpty ? _conversations.last : null;
      await _connection.disconnect();
    }
    await _storage.deleteMessages(id);
    await _storage.saveConversations(_conversations);
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connection.disconnect();
    super.dispose();
  }
}

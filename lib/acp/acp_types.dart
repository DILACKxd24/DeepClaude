/// ACP 协议类型定义

const String jsonRpcVersion = '2.0';

/// 会话更新类型
enum SessionUpdateType {
  agentMessageChunk,
  agentThoughtChunk,
  toolCall,
  toolCallUpdate,
  plan,
  availableCommandsUpdate,
  userMessageChunk,
}

/// 工具调用状态
enum ToolCallStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// 工具调用类型
enum ToolCallKind {
  read,
  edit,
  execute,
}

/// 会话更新基类
class SessionUpdate {
  final String sessionId;
  final SessionUpdateType type;
  final Map<String, dynamic> data;

  SessionUpdate({
    required this.sessionId,
    required this.type,
    required this.data,
  });

  factory SessionUpdate.fromJson(Map<String, dynamic> json) {
    final update = json['update'] as Map<String, dynamic>;
    final sessionUpdate = update['sessionUpdate'] as String;

    SessionUpdateType type;
    switch (sessionUpdate) {
      case 'agent_message_chunk':
        type = SessionUpdateType.agentMessageChunk;
        break;
      case 'agent_thought_chunk':
        type = SessionUpdateType.agentThoughtChunk;
        break;
      case 'tool_call':
        type = SessionUpdateType.toolCall;
        break;
      case 'tool_call_update':
        type = SessionUpdateType.toolCallUpdate;
        break;
      case 'plan':
        type = SessionUpdateType.plan;
        break;
      case 'available_commands_update':
        type = SessionUpdateType.availableCommandsUpdate;
        break;
      case 'user_message_chunk':
        type = SessionUpdateType.userMessageChunk;
        break;
      default:
        type = SessionUpdateType.agentMessageChunk;
    }

    return SessionUpdate(
      sessionId: json['sessionId'] ?? '',
      type: type,
      data: update,
    );
  }
}

/// 消息内容
class MessageContent {
  final String type; // text, image
  final String? text;
  final String? data;
  final String? mimeType;

  MessageContent({
    required this.type,
    this.text,
    this.data,
    this.mimeType,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: json['type'] ?? 'text',
      text: json['text'],
      data: json['data'],
      mimeType: json['mimeType'],
    );
  }
}

/// 工具调用内容
class ToolCallContent {
  final String type; // content, diff
  final String? text;
  final String? path;
  final String? oldText;
  final String? newText;

  ToolCallContent({
    required this.type,
    this.text,
    this.path,
    this.oldText,
    this.newText,
  });

  factory ToolCallContent.fromJson(Map<String, dynamic> json) {
    String? text;
    if (json['content'] != null && json['content']['text'] != null) {
      text = json['content']['text'];
    } else if (json['text'] != null) {
      text = json['text'];
    }

    return ToolCallContent(
      type: json['type'] ?? 'content',
      text: text,
      path: json['path'],
      oldText: json['oldText'],
      newText: json['newText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'path': path,
      'oldText': oldText,
      'newText': newText,
    };
  }
}

/// 工具调用数据
class ToolCallData {
  final String toolCallId;
  final ToolCallStatus status;
  final String title;
  final ToolCallKind kind;
  final List<ToolCallContent> content;
  final List<String> locations;
  final Map<String, dynamic>? rawInput;

  ToolCallData({
    required this.toolCallId,
    required this.status,
    required this.title,
    required this.kind,
    this.content = const [],
    this.locations = const [],
    this.rawInput,
  });

  factory ToolCallData.fromJson(Map<String, dynamic> json) {
    ToolCallStatus status;
    switch (json['status']) {
      case 'pending':
        status = ToolCallStatus.pending;
        break;
      case 'in_progress':
        status = ToolCallStatus.inProgress;
        break;
      case 'completed':
        status = ToolCallStatus.completed;
        break;
      case 'failed':
        status = ToolCallStatus.failed;
        break;
      default:
        status = ToolCallStatus.pending;
    }

    ToolCallKind kind;
    switch (json['kind']) {
      case 'read':
        kind = ToolCallKind.read;
        break;
      case 'edit':
        kind = ToolCallKind.edit;
        break;
      case 'execute':
        kind = ToolCallKind.execute;
        break;
      default:
        kind = ToolCallKind.execute;
    }

    final contentList = (json['content'] as List?)
            ?.map((c) => ToolCallContent.fromJson(c))
            .toList() ??
        [];

    // 支持两种格式的 locations
    List<String> locationsList = [];
    if (json['locations'] is List) {
      locationsList = (json['locations'] as List).map((l) {
        if (l is String) return l;
        if (l is Map && l['path'] != null) return l['path'] as String;
        return '';
      }).where((s) => s.isNotEmpty).toList();
    }

    return ToolCallData(
      toolCallId: json['toolCallId'] ?? '',
      status: status,
      title: json['title'] ?? 'Tool Call',
      kind: kind,
      content: contentList,
      locations: locationsList,
      rawInput: json['rawInput'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case ToolCallStatus.pending:
        statusStr = 'pending';
        break;
      case ToolCallStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case ToolCallStatus.completed:
        statusStr = 'completed';
        break;
      case ToolCallStatus.failed:
        statusStr = 'failed';
        break;
    }

    String kindStr;
    switch (kind) {
      case ToolCallKind.read:
        kindStr = 'read';
        break;
      case ToolCallKind.edit:
        kindStr = 'edit';
        break;
      case ToolCallKind.execute:
        kindStr = 'execute';
        break;
    }

    return {
      'toolCallId': toolCallId,
      'status': statusStr,
      'title': title,
      'kind': kindStr,
      'content': content.map((c) => c.toJson()).toList(),
      'locations': locations,
      'rawInput': rawInput,
    };
  }
}

/// 计划条目
class PlanEntry {
  final String content;
  final String status; // pending, in_progress, completed
  final String? priority; // low, medium, high

  PlanEntry({
    required this.content,
    required this.status,
    this.priority,
  });

  factory PlanEntry.fromJson(Map<String, dynamic> json) {
    return PlanEntry(
      content: json['content'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'status': status,
      'priority': priority,
    };
  }
}

/// 可用命令
class AvailableCommand {
  final String name;
  final String description;
  final String? hint;

  AvailableCommand({
    required this.name,
    required this.description,
    this.hint,
  });

  factory AvailableCommand.fromJson(Map<String, dynamic> json) {
    return AvailableCommand(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      hint: json['input']?['hint'],
    );
  }
}

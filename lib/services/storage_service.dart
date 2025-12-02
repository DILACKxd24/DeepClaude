import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/chat_provider.dart';
import '../acp/acp_types.dart';

/// 存储服务 - 持久化会话和消息
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  Directory? _dataDir;

  Future<Directory> get dataDir async {
    if (_dataDir != null) return _dataDir!;
    final appDir = await getApplicationSupportDirectory();
    _dataDir = Directory('${appDir.path}/claude_code_desktop');
    if (!await _dataDir!.exists()) {
      await _dataDir!.create(recursive: true);
    }
    return _dataDir!;
  }

  /// 保存会话列表
  Future<void> saveConversations(List<Conversation> conversations) async {
    final dir = await dataDir;
    final file = File('${dir.path}/conversations.json');

    final data = conversations.map((c) => _conversationToJson(c)).toList();
    await file.writeAsString(jsonEncode(data));
  }

  /// 加载会话列表
  Future<List<Conversation>> loadConversations() async {
    final dir = await dataDir;
    final file = File('${dir.path}/conversations.json');

    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.map((json) => _conversationFromJson(json)).toList();
    } catch (e) {
      print('加载会话失败: $e');
      return [];
    }
  }

  /// 保存单个会话的消息
  Future<void> saveMessages(String conversationId, List<ChatMessage> messages) async {
    final dir = await dataDir;
    final file = File('${dir.path}/messages_$conversationId.json');

    final data = messages.map((m) => _messageToJson(m)).toList();
    await file.writeAsString(jsonEncode(data));
  }

  /// 加载单个会话的消息
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final dir = await dataDir;
    final file = File('${dir.path}/messages_$conversationId.json');

    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('加载消息失败: $e');
      return [];
    }
  }

  /// 删除会话的消息文件
  Future<void> deleteMessages(String conversationId) async {
    final dir = await dataDir;
    final file = File('${dir.path}/messages_$conversationId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Map<String, dynamic> _conversationToJson(Conversation c) {
    return {
      'id': c.id,
      'name': c.name,
      'workingDir': c.workingDir,
      'createdAt': c.createdAt.toIso8601String(),
    };
  }

  Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'],
      workingDir: json['workingDir'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> _messageToJson(ChatMessage m) {
    final json = {
      'id': m.id,
      'type': m.type.index,
      'content': m.content,
      'timestamp': m.timestamp.toIso8601String(),
      'sequence': m.sequence,
      'isStreaming': m.isStreaming,
    };

    // 保存 planEntries
    if (m.planEntries != null && m.planEntries!.isNotEmpty) {
      json['planEntries'] = m.planEntries!.map((e) => e.toJson()).toList();
    }

    // 保存 toolCallData
    if (m.toolCallData != null) {
      json['toolCallData'] = m.toolCallData!.toJson();
    }

    // 保存 attachments
    if (m.attachments != null && m.attachments!.isNotEmpty) {
      json['attachments'] = m.attachments!.map((a) => a.toJson()).toList();
    }

    return json;
  }

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    // 解析 planEntries
    List<PlanEntry>? planEntries;
    if (json['planEntries'] != null) {
      planEntries = (json['planEntries'] as List)
          .map((e) => PlanEntry.fromJson(e))
          .toList();
    }

    // 解析 toolCallData
    ToolCallData? toolCallData;
    if (json['toolCallData'] != null) {
      toolCallData = ToolCallData.fromJson(json['toolCallData']);
    }

    // 解析 attachments
    List<FileAttachment>? attachments;
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((a) => FileAttachment.fromJson(a))
          .toList();
    }

    return ChatMessage(
      id: json['id'],
      type: MessageType.values[json['type']],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      sequence: json['sequence'] ?? 0,
      isStreaming: json['isStreaming'] ?? false,
      planEntries: planEntries,
      toolCallData: toolCallData,
      attachments: attachments,
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../acp/acp_connection.dart';
import '../acp/acp_types.dart';
import 'td_components.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<FileAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 选择文件
  Future<void> _pickFiles() async {
    print('[ChatArea] _pickFiles called');
    try {
      // 使用 public.item 允许选择所有文件类型
      const typeGroup = XTypeGroup(
        label: 'All Files',
        uniformTypeIdentifiers: ['public.item'],
      );
      
      print('[ChatArea] Opening file picker...');
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);
      
      if (files.isEmpty) {
        print('[ChatArea] No files selected');
        return;
      }
      
      print('[ChatArea] Selected ${files.length} files');
      
      for (final file in files) {
        try {
          print('[ChatArea] Reading file: ${file.path}');
          final fileObj = File(file.path);
          
          // 检查文件大小，限制为 100MB
          final stat = await fileObj.stat();
          if (stat.size > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('文件 ${file.name} 太大，最大支持 100MB')),
              );
            }
            continue;
          }
          
          // 根据文件类型决定读取方式
          String content;
          String mimeType = file.mimeType ?? _getMimeType(file.name);
          
          if (_isTextFile(file.name, mimeType)) {
            // 文本文件直接读取
            content = await fileObj.readAsString();
          } else {
            // 二进制文件（PDF、图片等）使用 base64 编码
            final bytes = await fileObj.readAsBytes();
            content = '[BASE64]${base64Encode(bytes)}';
          }
          
          setState(() {
            _pendingAttachments.add(FileAttachment(
              name: file.name,
              path: file.path,
              content: content,
              size: stat.size,
              mimeType: mimeType,
            ));
          });
          print('[ChatArea] Added attachment: ${file.name} (${mimeType})');
        } catch (e) {
          print('[ChatArea] Error reading file ${file.name}: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('无法读取文件 ${file.name}: $e')),
            );
          }
        }
      }
    } catch (e) {
      print('[ChatArea] Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  /// 判断是否为文本文件
  bool _isTextFile(String fileName, String mimeType) {
    final ext = fileName.split('.').last.toLowerCase();
    const textExtensions = [
      'txt', 'md', 'json', 'xml', 'html', 'htm', 'css', 'js', 'ts', 'jsx', 'tsx',
      'dart', 'py', 'java', 'kt', 'swift', 'c', 'cpp', 'h', 'hpp', 'cs', 'go',
      'rs', 'rb', 'php', 'sql', 'sh', 'bash', 'zsh', 'yaml', 'yml', 'toml',
      'ini', 'cfg', 'conf', 'env', 'gitignore', 'dockerfile', 'makefile',
      'gradle', 'properties', 'log', 'csv', 'tsv', 'svg', 'vue', 'svelte',
    ];
    return textExtensions.contains(ext) || mimeType.startsWith('text/');
  }

  /// 根据文件名获取 MIME 类型
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'zip': 'application/zip',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
      'json': 'application/json',
      'xml': 'application/xml',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'text/javascript',
      'txt': 'text/plain',
      'md': 'text/markdown',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// 移除附件
  void _removeAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: TDColors.getBgPage(isDark),
      child: Column(
        children: [
          // 顶部状态栏
          _buildTopBar(),

          // 消息列表
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                final messages = provider.currentConversation?.messages ?? [];
                
                // 按序列号排序显示
                final sortedMessages = List<ChatMessage>.from(messages)
                  ..sort((a, b) => a.sequence.compareTo(b.sequence));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  }
                });

                if (sortedMessages.isEmpty) {
                  return TDEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Start a conversation',
                    description: 'Type a message to begin',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  itemCount: sortedMessages.length,
                  itemBuilder: (context, index) {
                    final message = sortedMessages[index];
                    final showTimestamp = index == 0 ||
                        sortedMessages[index].timestamp.difference(
                          sortedMessages[index - 1].timestamp,
                        ).inMinutes > 5;
                    
                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: TDColors.getBgComponent(isDark),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimestamp(message.timestamp),
                                style: TextStyle(
                                  color: TDColors.getTextSecondary(isDark),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        MessageBubble(message: message),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final conversation = provider.currentConversation;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: TDColors.getBgContainer(isDark),
            border: Border(
              bottom: BorderSide(color: TDColors.getBorder(isDark)),
            ),
          ),
          child: Row(
            children: [
              // 工作目录信息
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: TDColors.getBgComponent(isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TDColors.getBorder(isDark)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      conversation?.name ?? '',
                      style: TextStyle(
                        color: TDColors.getTextPrimary(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 连接状态
              TDStatusIndicator(
                isActive: provider.isConnected,
                label: _getConnectionStateText(provider.connectionState),
              ),

              const SizedBox(width: 12),

              // 文件预览面板折叠按钮
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return _FoldButton(
                    isExpanded: settings.showFilePreview,
                    onTap: () => settings.toggleFilePreview(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getConnectionStateText(AcpConnectionState state) {
    switch (state) {
      case AcpConnectionState.disconnected:
        return 'Disconnected';
      case AcpConnectionState.connecting:
        return 'Connecting...';
      case AcpConnectionState.connected:
        return 'Connected';
      case AcpConnectionState.authenticated:
        return 'Authenticated';
      case AcpConnectionState.sessionActive:
        return 'Active';
      case AcpConnectionState.error:
        return 'Error';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays == 0) {
      // 今天，显示时间
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      return '${weekdays[timestamp.weekday % 7]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildInputArea() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentColor = Theme.of(context).colorScheme.primary;
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: TDColors.getBgContainer(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TDColors.getBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 附件预览区域
                if (_pendingAttachments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _pendingAttachments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attachment = entry.value;
                        return _AttachmentChip(
                          name: attachment.name,
                          size: attachment.size,
                          onRemove: () => _removeAttachment(index),
                        );
                      }).toList(),
                    ),
                  ),

                // 输入框
                RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (event) {
                    if (event is RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !event.isShiftPressed) {
                      _sendMessage(provider);
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      color: TDColors.getTextPrimary(isDark),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: _pendingAttachments.isEmpty 
                          ? 'Reply to Claude...' 
                          : 'Add a message about the files...',
                      hintStyle: TextStyle(
                        color: TDColors.getTextPlaceholder(isDark),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                  ),
                ),

                // 底部工具栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: TDColors.getBorder(isDark).withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 附件按钮
                      TDTooltipButton(
                        icon: Icons.attach_file_rounded,
                        tooltip: 'Attach files',
                        onTap: _pickFiles,
                      ),
                      const SizedBox(width: 6),
                      TDTooltipButton(
                        icon: Icons.code_rounded,
                        tooltip: 'Code block',
                        onTap: () {},
                      ),

                      const Spacer(),

                      // 模型选择
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: TDColors.getBgComponent(isDark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DeepClaude',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: TDColors.getTextSecondary(isDark),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: TDColors.getTextPlaceholder(isDark),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 发送按钮
                      GestureDetector(
                        onTap: provider.isLoading
                            ? null
                            : () => _sendMessage(provider),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: provider.isLoading
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [accentColor, accentColor.withOpacity(0.85)],
                                  ),
                            color: provider.isLoading ? TDColors.getBgComponent(isDark) : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: provider.isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: provider.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: TDColors.getTextSecondary(isDark),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendMessage(ChatProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    // 发送消息（带附件）
    provider.sendMessage(
      text.isEmpty ? '请分析这些文件' : text,
      attachments: _pendingAttachments.isNotEmpty ? List.from(_pendingAttachments) : null,
    );
    
    // 清空输入和附件
    _controller.clear();
    setState(() {
      _pendingAttachments.clear();
    });
  }
}

/// 附件标签
class _AttachmentChip extends StatelessWidget {
  final String name;
  final int size;
  final VoidCallback onRemove;

  const _AttachmentChip({
    required this.name,
    required this.size,
    required this.onRemove,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1a1a1a)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${_formatSize(size)})',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// 文件预览面板折叠按钮
class _FoldButton extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _FoldButton({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_FoldButton> createState() => _FoldButtonState();
}

class _FoldButtonState extends State<_FoldButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isExpanded ? '隐藏文件面板' : '显示文件面板',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.grey.shade200
                  : (widget.isExpanded
                      ? const Color(0xFFD97706).withOpacity(0.1)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.isExpanded
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              size: 18,
              color: widget.isExpanded
                  ? const Color(0xFFD97706)
                  : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ToolButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: Colors.grey[600],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;
  bool _isCopied = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    setState(() => _isCopied = true);
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // 2秒后重置图标
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.message.type) {
      case MessageType.user:
        return _buildUserMessage(context);
      case MessageType.assistant:
        return _buildAssistantMessage(context);
      case MessageType.system:
        return _buildSystemMessage();
      case MessageType.thinking:
        return _buildThinkingMessage();
      case MessageType.toolCall:
        return _buildToolCallMessage(context);
      case MessageType.permission:
        return _buildPermissionMessage(context);
      case MessageType.plan:
        return _buildPlanMessage(context);
    }
  }

  Widget _buildUserMessage(BuildContext context) {
    final attachments = widget.message.attachments;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'You',
                        style: TextStyle(
                          color: Color(0xFF1a1a1a),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_isHovered) _buildCopyButton(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 显示附件
                  if (attachments != null && attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attachments.map((a) => _buildAttachmentDisplay(a)).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    widget.message.content,
                    style: const TextStyle(
                      color: Color(0xFF1a1a1a),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentDisplay(FileAttachment attachment) {
    String formatSize(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 16, color: Colors.blue),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              attachment.name,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1a1a1a)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${formatSize(attachment.size)})',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Claude',
                        style: TextStyle(
                          color: Color(0xFF1a1a1a),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_isHovered && widget.message.content.isNotEmpty)
                        _buildCopyButton(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  widget.message.content.isEmpty && widget.message.isStreaming
                      ? const _TypingIndicator()
                      : MarkdownBody(
                          data: widget.message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Color(0xFF1a1a1a),
                              fontSize: 15,
                              height: 1.5,
                            ),
                            code: const TextStyle(
                              backgroundColor: Color(0xFFF3F4F6),
                              color: Color(0xFFD97706),
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyToClipboard(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          _isCopied ? Icons.check : Icons.copy,
          size: 14,
          color: _isCopied ? Colors.green : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.message.content,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue[400], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message.content,
                style: TextStyle(color: Colors.blue[700], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCallMessage(BuildContext context) {
    final toolCall = widget.message.toolCallData;
    final isCompleted = toolCall?.status.name == 'completed';
    final isFailed = toolCall?.status.name == 'failed';
    final isInProgress = toolCall?.status.name == 'inProgress';

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCompleted) {
      bgColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green[700]!;
    } else if (isFailed) {
      bgColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red[700]!;
    } else if (isInProgress) {
      bgColor = Colors.blue.withOpacity(0.05);
      borderColor = Colors.blue.withOpacity(0.2);
      textColor = Colors.blue[700]!;
    } else {
      bgColor = Colors.purple.withOpacity(0.05);
      borderColor = Colors.purple.withOpacity(0.2);
      textColor = Colors.purple[700]!;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isInProgress)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                else
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isFailed ? Icons.error : Icons.build),
                    color: textColor,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toolCall?.title ?? widget.message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (toolCall?.locations.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: toolCall!.locations.map((loc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      loc,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.indigo[400], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Plan',
                    style: TextStyle(
                      color: Colors.indigo[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_isHovered) _buildCopyButton(context),
                ],
              ),
              const SizedBox(height: 8),
              ...?widget.message.planEntries?.map((entry) {
                final statusIcon = switch (entry.status) {
                  'completed' => Icons.check_circle,
                  'in_progress' => Icons.sync,
                  _ => Icons.circle_outlined,
                };
                final statusColor = switch (entry.status) {
                  'completed' => Colors.green,
                  'in_progress' => Colors.blue,
                  _ => Colors.grey,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.content,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionMessage(BuildContext context) {
    final request = widget.message.permissionRequest;
    if (request == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.title,
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (request.description != null) ...[
              const SizedBox(height: 8),
              Text(
                request.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: request.options.map((option) {
                final isAllow = option.id.contains('allow');
                return ElevatedButton(
                  onPressed: () {
                    context
                        .read<ChatProvider>()
                        .respondToPermission(request.toolCallId, option.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllow
                        ? const Color(0xFF10B981)
                        : Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(option.name),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withOpacity(0.3 + value * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/mcp_provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_area.dart';
import '../widgets/title_bar.dart';
import '../widgets/file_preview_panel.dart';
import '../widgets/settings_panel.dart';
import '../widgets/mcp_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSettings = false;
  String? _settingsInitialSection;

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
      if (!_showSettings) {
        _settingsInitialSection = null;
      }
    });
  }

  void _openSettingsWithSection(String section) {
    setState(() {
      _showSettings = true;
      _settingsInitialSection = section;
    });
  }

  void _closeSettings() {
    setState(() {
      _showSettings = false;
      _settingsInitialSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                // 左侧边栏
                Sidebar(
                  onSettingsTap: _toggleSettings,
                  onCloseSettings: _closeSettings,
                ),
                
                // 主内容区：设置面板或聊天区域
                Expanded(
                  child: _showSettings
                      ? SettingsPanel(
                          onClose: _closeSettings,
                          initialSection: _settingsInitialSection,
                        )
                      : Row(
                          children: [
                            // 聊天区域
                            Expanded(
                              child: Consumer<ChatProvider>(
                                builder: (context, provider, _) {
                                  if (provider.currentConversation == null) {
                                    return WelcomeView(
                                      onOpenMcpSettings: () {
                                        // 打开设置面板并跳转到 MCP 部分
                                        _openSettingsWithSection('mcp');
                                      },
                                    );
                                  }
                                  return const ChatArea();
                                },
                              ),
                            ),
                            
                            // 文件预览面板
                            Consumer2<ChatProvider, SettingsProvider>(
                              builder: (context, chatProvider, settings, _) {
                                if (!settings.showFilePreview ||
                                    chatProvider.currentConversation == null) {
                                  return const SizedBox();
                                }
                                return FilePreviewPanel(
                                  workingDir: chatProvider.currentConversation!.workingDir,
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 欢迎页面 - TDesign 风格
class WelcomeView extends StatefulWidget {
  final VoidCallback? onOpenMcpSettings;
  
  const WelcomeView({super.key, this.onOpenMcpSettings});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  bool _useCustomDir = false;
  String? _customWorkingDir;
  final List<FileAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      const typeGroup = file_selector.XTypeGroup(
        label: 'All Files',
        uniformTypeIdentifiers: ['public.item'],
      );
      
      final files = await file_selector.openFiles(acceptedTypeGroups: [typeGroup]);
      if (files.isEmpty) return;
      
      for (final file in files) {
        try {
          final fileObj = File(file.path);
          final stat = await fileObj.stat();
          if (stat.size > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('文件 ${file.name} 太大，最大支持 100MB')),
              );
            }
            continue;
          }
          
          String content;
          String mimeType = file.mimeType ?? _getMimeType(file.name);
          
          if (_isTextFile(file.name, mimeType)) {
            content = await fileObj.readAsString();
          } else {
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
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('无法读取文件 ${file.name}: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

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

  void _removeAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // 顶部状态栏
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A870),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DeepClaude Desktop',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 主内容区
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 欢迎语
                    Column(
                      children: [
                        Text(
                          '欢迎使用 DeepClaude',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF181818),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation or select a project folder',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 输入框区域
                    Container(
                      width: 640,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 附件预览区域
                          if (_pendingAttachments.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                          TextField(
                            controller: _inputController,
                            focusNode: _focusNode,
                            maxLines: 8,
                            minLines: 2,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF181818),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: _pendingAttachments.isEmpty 
                                  ? 'Ask anything or describe what you want to build...' 
                                  : 'Add a message about the files...',
                              hintStyle: TextStyle(
                                color: isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            onSubmitted: (_) => _startConversation(),
                          ),

                          // 底部工具栏
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF0F0F0),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // 选择自定义工作目录按钮
                                _ToolButton(
                                  icon: Icons.folder_outlined,
                                  tooltip: _useCustomDir
                                      ? 'Working in: ${_customWorkingDir?.split('/').last ?? ""}'
                                      : 'Select project folder',
                                  isSelected: _useCustomDir,
                                  isHighlighted: false,
                                  onTap: _selectWorkingDir,
                                ),
                                const SizedBox(width: 6),
                                // 附件按钮
                                _ToolButton(
                                  icon: Icons.attach_file_rounded,
                                  tooltip: 'Attach files',
                                  onTap: _pickFiles,
                                ),
                                const SizedBox(width: 6),
                                // MCP 连接器按钮
                                McpMenuButton(
                                  onManageConnectors: widget.onOpenMcpSettings,
                                ),

                                const Spacer(),

                                // 显示选中的自定义目录
                                if (_useCustomDir && _customWorkingDir != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: accentColor.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.folder_rounded, size: 14, color: accentColor),
                                        const SizedBox(width: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 120),
                                          child: Text(
                                            _customWorkingDir!.split('/').last,
                                            style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _useCustomDir = false;
                                              _customWorkingDir = null;
                                            });
                                          },
                                          child: Icon(Icons.close_rounded, size: 14, color: accentColor),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (_useCustomDir && _customWorkingDir != null)
                                  const SizedBox(width: 12),

                                // 模型选择
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
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
                                        'Claude Code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: isDark ? const Color(0xFF888888) : const Color(0xFF999999),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // 发送按钮
                                GestureDetector(
                                  onTap: _startConversation,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [accentColor, accentColor.withOpacity(0.85)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
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

                    const SizedBox(height: 32),

                    // 快捷操作提示
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useCustomDir ? Icons.folder_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF888888) : const Color(0xFF999999),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _useCustomDir
                                ? 'Working in custom directory'
                                : 'Sessions saved in ~/.deepclaude',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectWorkingDir() async {
    try {
      final directory = await file_selector.getDirectoryPath();
      print('[WelcomeView] Selected directory: $directory');
      if (directory != null) {
        setState(() {
          _useCustomDir = true;
          _customWorkingDir = directory;
        });
      }
    } catch (e) {
      print('[WelcomeView] Error selecting directory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择目录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startConversation() async {
    print('[WelcomeView] _startConversation called');
    print('[WelcomeView] _useCustomDir: $_useCustomDir');
    print('[WelcomeView] _customWorkingDir: $_customWorkingDir');
    
    final message = _inputController.text.trim();
    print('[WelcomeView] Message: $message');
    print('[WelcomeView] Attachments: ${_pendingAttachments.length}');

    // 如果没有消息也没有附件，不执行
    if (message.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    try {
      final chatProvider = context.read<ChatProvider>();
      
      if (_useCustomDir && _customWorkingDir != null) {
        // 使用自定义目录
        print('[WelcomeView] Creating conversation with custom dir...');
        await chatProvider.createConversation(_customWorkingDir!);
      } else {
        // 自动创建会话目录
        print('[WelcomeView] Creating conversation with auto-generated dir...');
        await chatProvider.createNewConversation();
      }
      print('[WelcomeView] Conversation created successfully');

      // 发送消息（带附件）
      final messageToSend = message.isEmpty && _pendingAttachments.isNotEmpty 
          ? '请分析这些文件' 
          : message;
      
      if (messageToSend.isNotEmpty || _pendingAttachments.isNotEmpty) {
        print('[WelcomeView] Sending message with ${_pendingAttachments.length} attachments...');
        await chatProvider.sendMessage(
          messageToSend,
          attachments: _pendingAttachments.isNotEmpty ? List.from(_pendingAttachments) : null,
        );
        
        // 清空附件
        setState(() {
          _pendingAttachments.clear();
        });
      }
    } catch (e) {
      print('[WelcomeView] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建会话失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 工具按钮 - TDesign 风格
class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isHighlighted;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    Color bgColor;
    Color iconColor;
    
    if (widget.isSelected) {
      bgColor = accentColor.withOpacity(0.1);
      iconColor = accentColor;
    } else if (widget.isHighlighted) {
      bgColor = const Color(0xFFED7B2F).withOpacity(0.1);
      iconColor = const Color(0xFFED7B2F);
    } else if (_isHovered) {
      bgColor = isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);
      iconColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF666666);
    } else {
      bgColor = Colors.transparent;
      iconColor = isDark ? const Color(0xFF888888) : const Color(0xFF999999);
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: widget.isSelected || widget.isHighlighted
                  ? Border.all(
                      color: (widget.isSelected ? accentColor : const Color(0xFFED7B2F)).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class NewConversationDialog extends StatefulWidget {
  const NewConversationDialog({super.key});

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    if (settings.defaultWorkingDir.isNotEmpty) {
      _controller.text = settings.defaultWorkingDir;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'New Conversation',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF181818),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Working Directory',
            style: TextStyle(
              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF181818),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '/path/to/project',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _selectDirectory,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0052D9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0052D9).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: const Color(0xFF0052D9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Make sure Claude Code CLI is installed:\nnpm install -g @anthropics/claude-code',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF88AADD) : const Color(0xFF0052D9),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isLoading ? null : _createConversation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDirectory() async {
    final directory = await file_selector.getDirectoryPath();
    if (directory != null) {
      _controller.text = directory;
    }
  }

  Future<void> _createConversation() async {
    final dir = _controller.text.trim();
    if (dir.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await context.read<ChatProvider>().createConversation(dir);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// 附件标签 - TDesign 风格
class _AttachmentChip extends StatefulWidget {
  final String name;
  final int size;
  final VoidCallback onRemove;

  const _AttachmentChip({
    required this.name,
    required this.size,
    required this.onRemove,
  });

  @override
  State<_AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<_AttachmentChip> {
  bool _isHovered = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf_rounded;
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(ext)) return Icons.image_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    if (['zip', 'tar', 'gz', 'rar'].contains(ext)) return Icons.folder_zip_rounded;
    if (['mp3', 'wav', 'flac'].contains(ext)) return Icons.audio_file_rounded;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.video_file_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered 
              ? accentColor.withOpacity(0.15)
              : (isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered 
                ? accentColor.withOpacity(0.3)
                : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5)),
          ),
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
              child: Icon(_getFileIcon(widget.name), size: 14, color: accentColor),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                widget.name,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFE7E7E7) : const Color(0xFF181818),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatSize(widget.size),
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? const Color(0xFF888888) : const Color(0xFF999999),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.close_rounded, 
                  size: 12, 
                  color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// 欢迎页面 - Claude 风格
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

  bool _showMcpMenu = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Claude 风格的暖色背景
    final bgColor = isDark ? const Color(0xFF1A1816) : const Color(0xFFF5F1EB);
    final cardColor = isDark ? const Color(0xFF2A2724) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E4DE) : const Color(0xFF3D3929);
    final hintColor = isDark ? const Color(0xFF8A8680) : const Color(0xFF9A9590);
    final borderColor = isDark ? const Color(0xFF3A3734) : const Color(0xFFE5E0D8);
    const accentOrange = Color(0xFFD97757);
    
    return Container(
      color: bgColor,
      child: Column(
        children: [
          // 顶部右侧状态栏
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Free plan',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upgrade',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                    Text(
                      '欢迎使用 DeepClaude',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 输入框区域 - Claude 风格
                    Container(
                      width: 520,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 附件预览区域
                          if (_pendingAttachments.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            maxLines: 4,
                            minLines: 2,
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'How can I help you today?',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                            ),
                            onSubmitted: (_) => _startConversation(),
                          ),

                          // 底部工具栏
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Row(
                              children: [
                                // + 添加按钮
                                _ClaudeIconButton(
                                  child: Icon(Icons.add, size: 20, color: hintColor),
                                  onTap: _pickFiles,
                                ),
                                const SizedBox(width: 4),
                                // 滑块调节按钮
                                _ClaudeIconButton(
                                  child: Icon(Icons.tune, size: 18, color: hintColor),
                                  onTap: _selectWorkingDir,
                                ),
                                const SizedBox(width: 4),
                                // 时钟按钮 (MCP)
                                _ClaudeIconButton(
                                  child: Icon(Icons.schedule_outlined, size: 18, color: hintColor),
                                  onTap: () {
                                    setState(() {
                                      _showMcpMenu = !_showMcpMenu;
                                    });
                                  },
                                ),

                                const Spacer(),

                                // 模型选择器
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sonnet 4.5',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: hintColor,
                                      ),
                                    ),
                                    Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: hintColor,
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 8),

                                // 发送按钮 - 橙红色圆角方形
                                GestureDetector(
                                  onTap: _startConversation,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE07A5F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MCP 菜单弹出层
                    if (_showMcpMenu)
                      Container(
                        width: 520,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 搜索框
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: borderColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, size: 18, color: hintColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      style: TextStyle(fontSize: 14, color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Search menu',
                                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 菜单项
                            _McpMenuItem(
                              icon: Icons.edit_note_outlined,
                              title: 'Use style',
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.lightbulb_outline,
                              title: 'Extended thinking',
                              subtitle: '3 remaining until Dec 9',
                              hasToggle: true,
                              toggleValue: false,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.public,
                              title: 'Web search',
                              hasToggle: true,
                              toggleValue: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.grid_4x4,
                              iconColor: const Color(0xFF9333EA),
                              title: 'Context7',
                              hasToggle: true,
                              toggleValue: true,
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.circle,
                              iconColor: const Color(0xFFF97316),
                              title: 'Control Chrome',
                              hasToggle: true,
                              toggleValue: true,
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.terminal,
                              title: 'Control your Mac',
                              hasToggle: true,
                              toggleValue: true,
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.square_rounded,
                              iconColor: const Color(0xFFEF4444),
                              title: 'PDF Tools - Analyze, Extract, ...',
                              hasToggle: true,
                              toggleValue: true,
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.code,
                              title: 'videmcpServer',
                              hasToggle: true,
                              toggleValue: true,
                              hasArrow: true,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Divider(color: borderColor, height: 1),
                            ),
                            _McpMenuItem(
                              icon: Icons.add,
                              title: 'Add connectors',
                              badge: 'PRO',
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            _McpMenuItem(
                              icon: Icons.settings_outlined,
                              title: 'Manage connectors',
                              onTap: widget.onOpenMcpSettings,
                              textColor: textColor,
                              hintColor: hintColor,
                            ),
                            const SizedBox(height: 8),
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

/// Claude 风格图标按钮
class _ClaudeIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ClaudeIconButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_ClaudeIconButton> createState() => _ClaudeIconButtonState();
}

class _ClaudeIconButtonState extends State<_ClaudeIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark ? const Color(0xFF3A3734) : const Color(0xFFEAE6E0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// MCP 菜单项
class _McpMenuItem extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool hasArrow;
  final bool hasToggle;
  final bool toggleValue;
  final VoidCallback? onTap;
  final Color textColor;
  final Color hintColor;

  const _McpMenuItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.hasArrow = false,
    this.hasToggle = false,
    this.toggleValue = false,
    this.onTap,
    required this.textColor,
    required this.hintColor,
  });

  @override
  State<_McpMenuItem> createState() => _McpMenuItemState();
}

class _McpMenuItemState extends State<_McpMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark ? const Color(0xFF3A3734) : const Color(0xFFF5F1EB);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _isHovered ? hoverColor : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.iconColor ?? widget.hintColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.textColor,
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.hasToggle)
                _ClaudeToggle(value: widget.toggleValue),
              if (widget.hasArrow)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: widget.hintColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Claude 风格开关
class _ClaudeToggle extends StatelessWidget {
  final bool value;

  const _ClaudeToggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 22,
      decoration: BoxDecoration(
        color: value ? const Color(0xFF0EA5E9) : const Color(0xFFE5E0D8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
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
                    'Make sure DeepClaude CLI is installed:\nnpm install -g @anthropics/claude-code',
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

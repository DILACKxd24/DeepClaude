import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/home_screen.dart';
import 'td_components.dart';

class Sidebar extends StatefulWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onCloseSettings;
  
  const Sidebar({super.key, this.onSettingsTap, this.onCloseSettings});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _selectedTab = 'chats';
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final Set<String> _favoriteIds = {};
  final Set<String> _pinnedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: TDColors.getSidebarBg(isDark),
        border: Border(
          right: BorderSide(color: TDColors.getBorder(isDark)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 新建会话按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _NewChatButton(
              onTap: () => _createNewConversation(context),
            ),
          ),

          // 搜索栏
          _buildSearchBar(isDark),

          // 导航标签
          _buildNavigationTabs(isDark),

          const SizedBox(height: 8),

          // 内容区域
          Expanded(
            child: _buildContent(isDark),
          ),

          // 底部用户信息和设置
          _buildBottomSection(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: TDColors.getBgContainer(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isSearching ? accentColor : TDColors.getBorder(isDark),
            width: _isSearching ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              size: 18,
              color: TDColors.getTextPlaceholder(isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onTap: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTabs(bool isDark) {
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: TDColors.getBgComponent(isDark),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildTab('chats', 'Chats', Icons.chat_bubble_outline_rounded, isDark),
            const SizedBox(width: 4),
            _buildTab('favorites', 'Starred', Icons.star_outline_rounded, isDark),
            const SizedBox(width: 4),
            _buildTab('projects', 'Projects', Icons.folder_outlined, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == id;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = id;
          });
          if (id == 'chats') {
            widget.onCloseSettings?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TDColors.getBgContainer(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? accentColor
                    : TDColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? TDColors.getTextPrimary(isDark)
                      : TDColors.getTextSecondary(isDark),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_selectedTab) {
      case 'chats':
        return _buildChatsList(isDark);
      case 'favorites':
        return _buildFavoritesList(isDark);
      case 'projects':
        return _buildProjectsList(isDark);
      default:
        return _buildChatsList(isDark);
    }
  }

  Widget _buildChatsList(bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        var conversations = provider.conversations.toList();
        
        // 搜索过滤
        if (_searchQuery.isNotEmpty) {
          conversations = conversations.where((c) {
            return c.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   c.workingDir.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // 分离置顶和普通会话
        final pinnedConversations = conversations.where((c) => _pinnedIds.contains(c.id)).toList();
        final normalConversations = conversations.where((c) => !_pinnedIds.contains(c.id)).toList();

        if (conversations.isEmpty) {
          return _buildEmptyState(
            isDark,
            _searchQuery.isNotEmpty ? 'No results found' : 'No recent chats',
            _searchQuery.isNotEmpty ? 'Try a different search term' : 'Start a new conversation',
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            // 置顶会话
            if (pinnedConversations.isNotEmpty) ...[
              _buildSectionHeader('Pinned', isDark),
              ...pinnedConversations.map((conversation) {
                final isSelected = conversation.id == provider.currentConversation?.id;
                return _ConversationItem(
                  conversation: conversation,
                  isSelected: isSelected,
                  isPinned: true,
                  isFavorite: _favoriteIds.contains(conversation.id),
                  onTap: () => _selectConversation(provider, conversation),
                  onClose: () => _closeConversation(provider, conversation.id),
                  onPin: () => _togglePin(conversation.id),
                  onFavorite: () => _toggleFavorite(conversation.id),
                );
              }),
              const SizedBox(height: 8),
            ],

            // 最近会话
            if (normalConversations.isNotEmpty) ...[
              _buildSectionHeader('Recents', isDark),
              ...normalConversations.map((conversation) {
                final isSelected = conversation.id == provider.currentConversation?.id;
                return _ConversationItem(
                  conversation: conversation,
                  isSelected: isSelected,
                  isPinned: false,
                  isFavorite: _favoriteIds.contains(conversation.id),
                  onTap: () => _selectConversation(provider, conversation),
                  onClose: () => _closeConversation(provider, conversation.id),
                  onPin: () => _togglePin(conversation.id),
                  onFavorite: () => _toggleFavorite(conversation.id),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final favorites = provider.conversations
            .where((c) => _favoriteIds.contains(c.id))
            .toList();

        if (favorites.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No favorites yet',
            'Star conversations to add them here',
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            _buildSectionHeader('Favorites', isDark),
            ...favorites.map((conversation) {
              final isSelected = conversation.id == provider.currentConversation?.id;
              return _ConversationItem(
                conversation: conversation,
                isSelected: isSelected,
                isPinned: _pinnedIds.contains(conversation.id),
                isFavorite: true,
                onTap: () => _selectConversation(provider, conversation),
                onClose: () => _closeConversation(provider, conversation.id),
                onPin: () => _togglePin(conversation.id),
                onFavorite: () => _toggleFavorite(conversation.id),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildProjectsList(bool isDark) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        // 按工作目录分组
        final projectGroups = <String, List<Conversation>>{};
        for (final conv in provider.conversations) {
          final projectName = conv.workingDir.split('/').last;
          projectGroups.putIfAbsent(projectName, () => []).add(conv);
        }

        if (projectGroups.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No projects yet',
            'Conversations will be grouped by project',
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: projectGroups.entries.map((entry) {
            return _ProjectGroup(
              projectName: entry.key,
              conversations: entry.value,
              currentConversationId: provider.currentConversation?.id,
              onSelectConversation: (conv) => _selectConversation(provider, conv),
            );
          }).toList(),
        );
      },
    );
  }


  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final profile = settings.userProfile;
          return Row(
            children: [
              // 用户头像
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Consumer<ChatProvider>(
                      builder: (context, provider, _) {
                        return Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: provider.isConnected ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.isConnected ? 'Connected' : 'Offline',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 更多菜单按钮
              _buildMoreMenuButton(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMoreMenuButton(bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
      onSelected: (value) {
        switch (value) {
          case 'settings':
            widget.onSettingsTap?.call();
            break;
          case 'help':
            _showHelpDialog();
            break;
          case 'about':
            _showAboutDialog();
            break;
          case 'shortcuts':
            _showShortcutsDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem('settings', Icons.settings_outlined, 'Settings', isDark),
        _buildPopupMenuItem('shortcuts', Icons.keyboard_outlined, 'Keyboard Shortcuts', isDark),
        const PopupMenuDivider(),
        _buildPopupMenuItem('help', Icons.help_outline, 'Help & Support', isDark),
        _buildPopupMenuItem('about', Icons.info_outline, 'About', isDark),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String label, bool isDark) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1a1a1a),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _createNewConversation(BuildContext context) {
    // 清除当前会话，回到首页（WelcomeView）
    context.read<ChatProvider>().clearCurrentConversation();
    // 关闭设置面板（如果打开的话）
    widget.onCloseSettings?.call();
  }

  void _selectConversation(ChatProvider provider, Conversation conversation) {
    if (provider.currentConversation?.id != conversation.id) {
      provider.switchConversation(conversation.id);
      if (!provider.isConnected) {
        provider.reconnectConversation(conversation.id);
      }
    }
    widget.onCloseSettings?.call();
  }

  void _closeConversation(ChatProvider provider, String id) {
    final settings = context.read<SettingsProvider>();
    if (settings.confirmBeforeDelete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text('Are you sure you want to delete this conversation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.closeConversation(id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      provider.closeConversation(id);
    }
  }

  void _togglePin(String id) {
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
      } else {
        _pinnedIds.add(id);
      }
    });
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DeepClaude Desktop v1.0.0'),
            SizedBox(height: 16),
            Text('For help and documentation, visit:'),
            SizedBox(height: 8),
            Text('https://github.com/anthropics/claude-code', style: TextStyle(color: Color(0xFF3B82F6))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('DeepClaude Desktop'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('A desktop client for Claude Code via ACP protocol.'),
            SizedBox(height: 16),
            Text('Built with Flutter ❤️'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            final shortcuts = settings.shortcuts;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShortcutRow('New Chat', shortcuts.newChat),
                _buildShortcutRow('Search', shortcuts.search),
                _buildShortcutRow('Settings', shortcuts.settings),
                _buildShortcutRow('Toggle Sidebar', shortcuts.toggleSidebar),
                _buildShortcutRow('Send Message', shortcuts.sendMessage),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String action, String shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(action)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// 侧边栏菜单项
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? Colors.grey.shade700 : Colors.grey.shade200)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isHighlighted
                    ? const Color(0xFFD97706)
                    : (isDark ? Colors.white : const Color(0xFF1a1a1a)),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                  fontSize: 14,
                  fontWeight: widget.isHighlighted ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 会话列表项
class _ConversationItem extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final bool isPinned;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onPin;
  final VoidCallback onFavorite;

  const _ConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.isPinned,
    required this.isFavorite,
    required this.onTap,
    required this.onClose,
    required this.onPin,
    required this.onFavorite,
  });

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                : (_isHovered
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 图标
              if (widget.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.push_pin,
                    size: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              if (widget.isFavorite && !widget.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.amber[600],
                  ),
                ),
              
              // 标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.displayTitle,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                        fontSize: 13,
                        fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (_isHovered || widget.isSelected)
                      Text(
                        widget.conversation.workingDir.split('/').last,
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              
              // 操作按钮
              if (_isHovered) ...[
                GestureDetector(
                  onTap: widget.onFavorite,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      widget.isFavorite ? Icons.star : Icons.star_outline,
                      size: 16,
                      color: widget.isFavorite ? Colors.amber[600] : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: widget.onPin,
          child: Row(
            children: [
              Icon(
                widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Text(widget.isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        PopupMenuItem<void>(
          onTap: widget.onFavorite,
          child: Row(
            children: [
              Icon(
                widget.isFavorite ? Icons.star : Icons.star_outline,
                size: 18,
                color: widget.isFavorite ? Colors.amber[600] : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 10),
              Text(widget.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () {
            // TODO: Implement rename
          },
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 10),
              const Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<void>(
          onTap: () {
            // TODO: Implement duplicate
          },
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 10),
              const Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: widget.onClose,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      ],
    );
  }
}

/// 项目分组
class _ProjectGroup extends StatefulWidget {
  final String projectName;
  final List<Conversation> conversations;
  final String? currentConversationId;
  final Function(Conversation) onSelectConversation;

  const _ProjectGroup({
    required this.projectName,
    required this.conversations,
    required this.currentConversationId,
    required this.onSelectConversation,
  });

  @override
  State<_ProjectGroup> createState() => _ProjectGroupState();
}

class _ProjectGroupState extends State<_ProjectGroup> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目标题
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.folder,
                  size: 16,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.projectName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.conversations.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 会话列表
        if (_isExpanded)
          ...widget.conversations.map((conv) {
            final isSelected = conv.id == widget.currentConversationId;
            return _ProjectConversationItem(
              conversation: conv,
              isSelected: isSelected,
              onTap: () => widget.onSelectConversation(conv),
            );
          }),
        
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ProjectConversationItem extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ProjectConversationItem> createState() => _ProjectConversationItemState();
}

class _ProjectConversationItemState extends State<_ProjectConversationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 24, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                : (_isHovered
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.conversation.displayTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 新建聊天按钮 - TDesign 风格
class _NewChatButton extends StatefulWidget {
  final VoidCallback onTap;

  const _NewChatButton({required this.onTap});

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [accentColor, accentColor.withOpacity(0.85)]
                  : [accentColor.withOpacity(0.9), accentColor.withOpacity(0.75)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(_isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'New Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⌘N',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/settings_provider.dart' as settings_provider;
import '../providers/provider_manager.dart';
import '../providers/locale_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/mcp_provider.dart';
import '../models/provider_config.dart';
import 'mcp_settings.dart';

// 为了避免与 Flutter 的 ThemeMode 冲突，使用别名
typedef AppThemeMode = settings_provider.ThemeMode;
typedef _SettingsProvider = settings_provider.SettingsProvider;
typedef _KeyboardShortcuts = settings_provider.KeyboardShortcuts;

class SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final String? initialSection;

  const SettingsPanel({super.key, required this.onClose, this.initialSection});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late String _selectedSection;
  bool _showProviderDetail = false;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection ?? 'general';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF9F6),
      child: Row(
        children: [
          // 左侧导航栏
          Container(
            width: 180,
            color: const Color(0xFFF5F4F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Consumer<LocaleProvider>(
                  builder: (context, locale, _) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Icon(Icons.arrow_back, size: 18, color: Colors.grey[700]),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.settings(locale.language),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _buildNavigation(),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Consumer<LocaleProvider>(
      builder: (context, locale, _) {
        final lang = locale.language;
        return Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavItem('general', AppStrings.general(lang), Icons.settings_outlined),
                _buildNavItem('account', AppStrings.account(lang), Icons.person_outline),
                _buildNavItem('privacy', AppStrings.privacy(lang), Icons.lock_outline),
                _buildNavItem('model', AppStrings.model(lang), Icons.auto_awesome_outlined),
                _buildNavItem('mcp', 'MCP Servers', Icons.extension_outlined),
                
                const SizedBox(height: 20),
                _buildSectionHeader(AppStrings.desktopApp(lang)),
                const SizedBox(height: 8),
                
                _buildNavItem('appearance', AppStrings.appearance(lang), Icons.palette_outlined),
                _buildNavItem('editor', 'Editor', Icons.code_outlined),
                _buildNavItem('permissions', AppStrings.permissions(lang), Icons.security_outlined),
                _buildNavItem('notifications', 'Notifications', Icons.notifications_outlined),
                _buildNavItem('shortcuts', 'Shortcuts', Icons.keyboard_outlined),
                _buildNavItem('network', 'Network', Icons.wifi_outlined),
                _buildNavItem('advanced', 'Advanced', Icons.tune_outlined),
                _buildNavItem('data', AppStrings.developer(lang), Icons.developer_mode_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNavItem(String id, String label, IconData icon) {
    final isSelected = _selectedSection == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedSection = id;
            _showProviderDetail = false;
          }),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? const Color(0xFFD97706) : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF1a1a1a) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showProviderDetail) {
      return _buildProviderDetailContent();
    }
    
    return Container(
      color: const Color(0xFFFAF9F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildSectionContent(),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'general':
        return _buildGeneralSection();
      case 'account':
        return _buildAccountSection();
      case 'privacy':
        return _buildPrivacySection();
      case 'model':
        return _buildModelSection();
      case 'mcp':
        return _buildMcpSection();
      case 'appearance':
        return _buildAppearanceSection();
      case 'editor':
        return _buildEditorSection();
      case 'permissions':
        return _buildPermissionsSection();
      case 'notifications':
        return _buildNotificationsSection();
      case 'shortcuts':
        return _buildShortcutsSection();
      case 'network':
        return _buildNetworkSection();
      case 'advanced':
        return _buildAdvancedSection();
      case 'data':
        return _buildDeveloperSection();
      default:
        return _buildGeneralSection();
    }
  }

  Widget _buildMcpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('MCP Servers'),
        const SizedBox(height: 8),
        Text(
          'Model Context Protocol servers extend Claude\'s capabilities with external tools and data sources.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const McpSettingsSection(),
        ),
      ],
    );
  }


  Widget _buildGeneralSection() {
    return Consumer2<settings_provider.SettingsProvider, LocaleProvider>(
      builder: (context, settings, locale, _) {
        final lang = locale.language;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppStrings.general(lang)),
            const SizedBox(height: 20),

            // 语言选择
            _buildSettingCard(
              title: AppStrings.language(lang),
              description: AppStrings.languageDesc(lang),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppLanguage>(
                    value: lang,
                    isExpanded: true,
                    items: AppLanguage.values.map((l) {
                      return DropdownMenuItem(
                        value: l,
                        child: Text(l.displayName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) locale.setLanguage(v);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 默认工作目录
            _buildSettingCard(
              title: AppStrings.defaultWorkingDir(lang),
              description: AppStrings.defaultWorkingDirDesc(lang),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        settings.defaultWorkingDir.isEmpty
                            ? '~/.deepclaude'
                            : settings.defaultWorkingDir,
                        style: TextStyle(
                          fontSize: 13,
                          color: settings.defaultWorkingDir.isEmpty
                              ? Colors.grey[500]
                              : const Color(0xFF1a1a1a),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(AppStrings.browse(lang), () => _selectDir(settings)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 启动时行为
            _buildSettingCard(
              title: 'Startup Behavior',
              description: 'What to show when the app starts',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'welcome',
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'welcome', child: Text('Welcome screen', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'last', child: Text('Last conversation', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'new', child: Text('New conversation', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {},
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        final profile = settings.userProfile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account'),
            const SizedBox(height: 20),

            // 用户资料卡片
            _buildSettingCard(
              title: 'Profile',
              description: 'Your account information',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showEditAvatarDialog(settings),
                      child: Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Center(
                              child: Text(
                                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(Icons.camera_alt, size: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (profile.email.isNotEmpty)
                            Text(
                              profile.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildButton('Edit', () => _showEditProfileDialog(settings)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API Key 设置
            _buildSettingCard(
              title: 'API Key',
              description: 'Your Anthropic API key for direct access',
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        profile.apiKey != null && profile.apiKey!.isNotEmpty
                            ? '••••••••${profile.apiKey!.substring(profile.apiKey!.length - 4)}'
                            : 'Not set',
                        style: TextStyle(
                          fontSize: 13,
                          color: profile.apiKey != null ? const Color(0xFF1a1a1a) : Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildButton('Set Key', () => _showApiKeyDialog(settings)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacySection() {
    return Consumer2<settings_provider.SettingsProvider, LocaleProvider>(
      builder: (context, settings, locale, _) {
        final lang = locale.language;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppStrings.privacy(lang)),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: AppStrings.dataCollection(lang),
              description: AppStrings.dataCollectionDesc(lang),
              value: locale.dataCollection,
              onChanged: (v) => locale.setDataCollection(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Confirm Before Delete',
              description: 'Ask for confirmation before deleting conversations',
              value: settings.confirmBeforeDelete,
              onChanged: (v) => settings.setConfirmBeforeDelete(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: AppStrings.clearHistory(lang),
              description: AppStrings.clearHistoryDesc(lang),
              child: Row(
                children: [
                  _buildButton(
                    AppStrings.clearHistoryBtn(lang),
                    () => _confirmClear(settings),
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Export Data',
              description: 'Download all your data and conversations',
              child: Row(
                children: [
                  _buildButton('Export', () => _exportData(settings)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelSection() {
    return Consumer2<ProviderManager, LocaleProvider>(
      builder: (context, providerManager, locale, _) {
        final lang = locale.language;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(AppStrings.model(lang)),
                GestureDetector(
                  onTap: () => _showAddProviderDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(AppStrings.add(lang), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppStrings.aiProviderDesc(lang), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),

            // 模型列表
            ...providerManager.providers.map((provider) {
              final isSelected = providerManager.currentProvider?.id == provider.id;
              return _buildProviderCard(
                provider: provider,
                isSelected: isSelected,
                onTap: () => providerManager.setCurrentProvider(provider),
                onEdit: () => _showEditProviderDialog(provider),
                onDelete: provider.isOfficial ? null : () => _confirmDeleteProvider(providerManager, provider),
              );
            }),

            const SizedBox(height: 24),

            // 连接状态
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return _buildSettingCard(
                  title: 'Connection Status',
                  description: 'Current connection to Claude Code CLI',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: chatProvider.isConnected ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          chatProvider.isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            fontSize: 13,
                            color: chatProvider.isConnected ? Colors.green : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildAppearanceSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 20),

            // 主题选择
            _buildSettingCard(
              title: 'Theme',
              description: 'Choose your preferred color theme',
              child: Row(
                children: [
                  _buildThemeOption(
                    'Light',
                    Icons.light_mode,
                    settings.themeMode == AppThemeMode.light,
                    () => settings.setThemeMode(AppThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'Dark',
                    Icons.dark_mode,
                    settings.themeMode == AppThemeMode.dark,
                    () => settings.setThemeMode(AppThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'System',
                    Icons.settings_suggest,
                    settings.themeMode == AppThemeMode.system,
                    () => settings.setThemeMode(AppThemeMode.system),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 强调色
            _buildSettingCard(
              title: 'Accent Color',
              description: 'Choose the primary accent color',
              child: Row(
                children: [
                  _buildColorOption('#D97706', settings.accentColor == '#D97706', () => settings.setAccentColor('#D97706')),
                  const SizedBox(width: 8),
                  _buildColorOption('#3B82F6', settings.accentColor == '#3B82F6', () => settings.setAccentColor('#3B82F6')),
                  const SizedBox(width: 8),
                  _buildColorOption('#10B981', settings.accentColor == '#10B981', () => settings.setAccentColor('#10B981')),
                  const SizedBox(width: 8),
                  _buildColorOption('#8B5CF6', settings.accentColor == '#8B5CF6', () => settings.setAccentColor('#8B5CF6')),
                  const SizedBox(width: 8),
                  _buildColorOption('#EF4444', settings.accentColor == '#EF4444', () => settings.setAccentColor('#EF4444')),
                  const SizedBox(width: 8),
                  _buildColorOption('#EC4899', settings.accentColor == '#EC4899', () => settings.setAccentColor('#EC4899')),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 字体大小
            _buildSettingCard(
              title: 'Font Size',
              description: 'Chat message font size',
              child: Row(
                children: [
                  Text('${settings.fontSize.toInt()}px', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 12,
                      max: 20,
                      divisions: 8,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) => settings.setFontSize(v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Compact Mode',
              description: 'Use smaller spacing and padding',
              value: settings.compactMode,
              onChanged: (v) => settings.setCompactMode(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'File Preview Panel',
              description: 'Show file browser on the right',
              value: settings.showFilePreview,
              onChanged: (v) => settings.setShowFilePreview(v),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD97706).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFD97706) : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFFD97706) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(String colorHex, bool isSelected, VoidCallback onTap) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildEditorSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Editor'),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: 'Auto Save',
              description: 'Automatically save changes',
              value: settings.autoSave,
              onChanged: (v) => settings.setAutoSave(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Auto Save Interval',
              description: 'How often to auto save (in seconds)',
              child: Row(
                children: [
                  Text('${settings.autoSaveInterval}s', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: settings.autoSaveInterval.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 11,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) => settings.setAutoSaveInterval(v.toInt()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Word Wrap',
              description: 'Wrap long lines in the editor',
              value: settings.wordWrap,
              onChanged: (v) => settings.setWordWrap(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Show Line Numbers',
              description: 'Display line numbers in code blocks',
              value: settings.showLineNumbers,
              onChanged: (v) => settings.setShowLineNumbers(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Tab Size',
              description: 'Number of spaces for indentation',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: settings.tabSize,
                    isExpanded: true,
                    items: [2, 4, 8].map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size spaces', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) settings.setTabSize(v);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Code Font',
              description: 'Font family for code blocks',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.codeFont,
                    isExpanded: true,
                    items: ['JetBrains Mono', 'Fira Code', 'Source Code Pro', 'Menlo', 'Monaco'].map((font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) settings.setCodeFont(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionsSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Permissions'),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: 'Auto-approve File Read',
              description: 'Allow Claude to read files without asking',
              value: settings.autoApproveRead,
              onChanged: (v) => settings.setAutoApproveRead(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Auto-approve File Write',
              description: 'Allow Claude to write files (use with caution)',
              value: settings.autoApproveWrite,
              onChanged: (v) => settings.setAutoApproveWrite(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Auto-approve Command Execution',
              description: 'Allow Claude to run shell commands (dangerous)',
              value: settings.autoApproveExecute,
              onChanged: (v) => settings.setAutoApproveExecute(v),
              isDangerous: true,
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Show Hidden Files',
              description: 'Display hidden files in file browser',
              value: settings.showHiddenFiles,
              onChanged: (v) => settings.setShowHiddenFiles(v),
            ),
          ],
        );
      },
    );
  }


  Widget _buildNotificationsSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        final notifications = settings.notifications;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: 'Enable Notifications',
              description: 'Show desktop notifications',
              value: notifications.enabled,
              onChanged: (v) => settings.setNotifications(notifications.copyWith(enabled: v)),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Sound',
              description: 'Play sound for notifications',
              value: notifications.soundEnabled,
              onChanged: notifications.enabled
                  ? (v) => settings.setNotifications(notifications.copyWith(soundEnabled: v))
                  : null,
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Show Preview',
              description: 'Show message preview in notifications',
              value: notifications.showPreview,
              onChanged: notifications.enabled
                  ? (v) => settings.setNotifications(notifications.copyWith(showPreview: v))
                  : null,
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Task Complete',
              description: 'Notify when a task is completed',
              value: notifications.taskComplete,
              onChanged: notifications.enabled
                  ? (v) => settings.setNotifications(notifications.copyWith(taskComplete: v))
                  : null,
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Error Alerts',
              description: 'Notify when an error occurs',
              value: notifications.errorAlert,
              onChanged: notifications.enabled
                  ? (v) => settings.setNotifications(notifications.copyWith(errorAlert: v))
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildShortcutsSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        final shortcuts = settings.shortcuts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Keyboard Shortcuts'),
            const SizedBox(height: 20),

            _buildShortcutItem('New Chat', shortcuts.newChat),
            const SizedBox(height: 12),
            _buildShortcutItem('Search', shortcuts.search),
            const SizedBox(height: 12),
            _buildShortcutItem('Settings', shortcuts.settings),
            const SizedBox(height: 12),
            _buildShortcutItem('Toggle Sidebar', shortcuts.toggleSidebar),
            const SizedBox(height: 12),
            _buildShortcutItem('Send Message', shortcuts.sendMessage),

            const SizedBox(height: 24),

            _buildSettingCard(
              title: 'Reset Shortcuts',
              description: 'Restore all shortcuts to default values',
              child: _buildButton('Reset', () {
                settings.setShortcuts(_KeyboardShortcuts());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shortcuts reset to defaults')),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShortcutItem(String action, String shortcut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Network'),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: 'Use Proxy',
              description: 'Route requests through a proxy server',
              value: settings.useProxy,
              onChanged: (v) => settings.setUseProxy(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Proxy URL',
              description: 'HTTP/HTTPS proxy server address',
              child: TextField(
                controller: TextEditingController(text: settings.proxyUrl),
                enabled: settings.useProxy,
                decoration: InputDecoration(
                  hintText: 'http://proxy.example.com:8080',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => settings.setProxyUrl(v),
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Request Timeout',
              description: 'Maximum time to wait for a response (seconds)',
              child: Row(
                children: [
                  Text('${settings.requestTimeout}s', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: settings.requestTimeout.toDouble(),
                      min: 30,
                      max: 300,
                      divisions: 9,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) => settings.setRequestTimeout(v.toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedSection() {
    return Consumer<settings_provider.SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Advanced'),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: 'Enable Beta Features',
              description: 'Try experimental features before they are released',
              value: settings.enableBetaFeatures,
              onChanged: (v) => settings.setEnableBetaFeatures(v),
            ),

            const SizedBox(height: 16),

            _buildSwitchCard(
              title: 'Send Telemetry',
              description: 'Help improve the app by sending anonymous usage data',
              value: settings.enableTelemetry,
              onChanged: (v) => settings.setEnableTelemetry(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Max History Items',
              description: 'Maximum number of conversations to keep',
              child: Row(
                children: [
                  Text('${settings.maxHistoryItems}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: settings.maxHistoryItems.toDouble(),
                      min: 10,
                      max: 500,
                      divisions: 49,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) => settings.setMaxHistoryItems(v.toInt()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Reset All Settings',
              description: 'Restore all settings to their default values',
              child: _buildButton(
                'Reset to Defaults',
                () => _confirmResetSettings(settings),
                isDestructive: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeveloperSection() {
    return Consumer2<settings_provider.SettingsProvider, LocaleProvider>(
      builder: (context, settings, locale, _) {
        final lang = locale.language;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppStrings.developer(lang)),
            const SizedBox(height: 20),

            _buildSwitchCard(
              title: AppStrings.debugMode(lang),
              description: AppStrings.debugModeDesc(lang),
              value: locale.debugMode,
              onChanged: (v) => locale.setDebugMode(v),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: AppStrings.version(lang),
              description: 'DeepClaude Desktop v1.0.0',
              child: Row(
                children: [
                  _buildButton(
                    AppStrings.checkUpdates(lang),
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Already up to date!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Export Settings',
              description: 'Save your settings to a file',
              child: _buildButton('Export', () async {
                final path = await settings.exportSettings();
                if (path != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings exported to: $path')),
                  );
                }
              }),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Import Settings',
              description: 'Load settings from a file',
              child: _buildButton('Import', () => _importSettings(settings)),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Open Config Directory',
              description: 'Open the configuration folder in Finder',
              child: _buildButton('Open', () {
                // TODO: Implement open config directory
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening config directory...')),
                );
              }),
            ),
          ],
        );
      },
    );
  }


  // Provider Detail Content
  Widget _buildProviderDetailContent() {
    return Container(
      color: const Color(0xFFFAF9F6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showProviderDetail = false),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Settings',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddProviderDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ProviderManager>(
              builder: (context, manager, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'AI Providers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1a1a1a)),
                    ),
                    const SizedBox(height: 8),
                    Text('Select a provider for Claude Code', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ...manager.providers.map((provider) {
                      final isSelected = manager.currentProvider?.id == provider.id;
                      return _buildProviderCard(
                        provider: provider,
                        isSelected: isSelected,
                        onTap: () => manager.setCurrentProvider(provider),
                        onEdit: () => _showEditProviderDialog(provider),
                        onDelete: provider.isOfficial ? null : () => _confirmDeleteProvider(manager, provider),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required ProviderConfig provider,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(provider.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        if (provider.isOfficial) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Official', style: TextStyle(fontSize: 9, color: Color(0xFFD97706))),
                          ),
                        ],
                      ],
                    ),
                    Text(provider.model ?? 'Default', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFFD97706), size: 20)
              else ...[
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete, size: 16, color: Colors.grey[400]),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1a1a1a)),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1a1a1a))),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String description,
    required bool value,
    ValueChanged<bool>? onChanged,
    bool isDangerous = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDangerous && value ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1a1a1a))),
                    if (isDangerous) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Dangerous', style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: isDangerous ? Colors.red : const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDestructive ? Colors.red.shade200 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDestructive ? Colors.red : const Color(0xFF1a1a1a),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Dialog Methods
  Future<void> _selectDir(_SettingsProvider settings) async {
    final directory = await getDirectoryPath();
    if (directory != null) {
      await settings.setDefaultWorkingDir(directory);
    }
  }

  void _confirmClear(_SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all conversations? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              settings.clearAllHistory();
              context.read<ChatProvider>().conversations.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmResetSettings(_SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to default values? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings reset to defaults')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAddProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProviderEditDialog(
        onSave: (provider) => context.read<ProviderManager>().addProvider(provider),
      ),
    );
  }

  void _showEditProviderDialog(ProviderConfig provider) {
    showDialog(
      context: context,
      builder: (context) => _ProviderEditDialog(
        provider: provider,
        onSave: (updated) => context.read<ProviderManager>().updateProvider(updated),
      ),
    );
  }

  void _confirmDeleteProvider(ProviderManager manager, ProviderConfig provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Delete "${provider.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              manager.deleteProvider(provider.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(_SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.userProfile.name);
    final emailController = TextEditingController(text: settings.userProfile.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settings.setUserProfile(settings.userProfile.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAvatarDialog(_SettingsProvider settings) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar editing coming soon!')),
    );
  }

  void _showApiKeyDialog(_SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userProfile.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-ant-...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settings.setUserProfile(settings.userProfile.copyWith(apiKey: controller.text.trim()));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(_SettingsProvider settings) async {
    final path = await settings.exportSettings();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data exported to: $path')));
    }
  }

  Future<void> _importSettings(_SettingsProvider settings) async {
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final success = await settings.importSettings(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Settings imported successfully' : 'Failed to import settings')),
        );
      }
    }
  }
}

/// Provider Edit Dialog
class _ProviderEditDialog extends StatefulWidget {
  final ProviderConfig? provider;
  final Function(ProviderConfig) onSave;

  const _ProviderEditDialog({this.provider, required this.onSave});

  @override
  State<_ProviderEditDialog> createState() => _ProviderEditDialogState();
}

class _ProviderEditDialogState extends State<_ProviderEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _authTokenController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _baseUrlController = TextEditingController(text: widget.provider?.baseUrl ?? '');
    _authTokenController = TextEditingController(text: widget.provider?.authToken ?? '');
    _modelController = TextEditingController(text: widget.provider?.model ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _authTokenController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.provider != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Provider' : 'Add Provider'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. My Provider')),
            const SizedBox(height: 16),
            TextField(controller: _baseUrlController, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.example.com')),
            const SizedBox(height: 16),
            TextField(controller: _authTokenController, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', hintText: 'sk-...')),
            const SizedBox(height: 16),
            TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. claude-3-5-sonnet')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    final provider = ProviderConfig(
      id: widget.provider?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      baseUrl: _baseUrlController.text.trim().isEmpty ? null : _baseUrlController.text.trim(),
      authToken: _authTokenController.text.trim().isEmpty ? null : _authTokenController.text.trim(),
      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
    );

    widget.onSave(provider);
    Navigator.pop(context);
  }
}

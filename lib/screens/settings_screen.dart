import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/settings_provider.dart';
import '../providers/provider_manager.dart';
import 'provider_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = 'general';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        children: [
          // 左侧导航栏
          _buildLeftNav(),
          
          // 右侧内容区
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftNav() {
    return Container(
      width: 200,
      color: const Color(0xFFF5F4F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 导航项
          _buildNavItem('general', 'General', Icons.settings_outlined),
          _buildNavItem('model', 'Model', Icons.api_outlined),
          _buildNavItem('permissions', 'Permissions', Icons.security_outlined),
          _buildNavItem('appearance', 'Appearance', Icons.palette_outlined),
          _buildNavItem('data', 'Data', Icons.storage_outlined),
          _buildNavItem('about', 'About', Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildNavItem(String id, String label, IconData icon) {
    final isSelected = _selectedSection == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedSection = id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? const Color(0xFFD97706) : Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF1a1a1a) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
    return Container(
      color: const Color(0xFFFAF9F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
      case 'model':
        return _buildModelSection();
      case 'permissions':
        return _buildPermissionsSection();
      case 'appearance':
        return _buildAppearanceSection();
      case 'data':
        return _buildDataSection();
      case 'about':
        return _buildAboutSection();
      default:
        return _buildGeneralSection();
    }
  }

  Widget _buildGeneralSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General'),
            const SizedBox(height: 24),

            // 默认工作目录
            _buildSettingCard(
              title: 'Default Working Directory',
              description: 'Set the default directory for new conversations',
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        settings.defaultWorkingDir.isEmpty
                            ? 'Not set (uses ~/.deepclaude)'
                            : settings.defaultWorkingDir,
                        style: TextStyle(
                          color: settings.defaultWorkingDir.isEmpty
                              ? Colors.grey[500]
                              : const Color(0xFF1a1a1a),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _selectDefaultDir(context, settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Browse'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelSection() {
    return Consumer<ProviderManager>(
      builder: (context, providerManager, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Model Configuration'),
            const SizedBox(height: 24),

            _buildSettingCard(
              title: 'AI Provider',
              description: 'Configure the AI provider and model settings',
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProviderSettingsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerManager.currentProvider?.name ?? 'Not configured',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                            Text(
                              providerManager.currentProvider?.model ?? 'Click to configure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Permissions'),
            const SizedBox(height: 24),

            _buildSettingCard(
              title: 'Auto-approve File Read',
              description: 'Automatically allow Claude to read files without asking',
              child: _buildSwitch(
                value: settings.autoApproveRead,
                onChanged: (v) => settings.setAutoApproveRead(v),
              ),
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: 'Auto-approve File Write',
              description: 'Automatically allow Claude to write files (use with caution)',
              child: _buildSwitch(
                value: settings.autoApproveWrite,
                onChanged: (v) => settings.setAutoApproveWrite(v),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 24),

            _buildSettingCard(
              title: 'Font Size',
              description: 'Adjust the chat font size',
              child: Row(
                children: [
                  Text('${settings.fontSize.toInt()}px',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
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

            _buildSettingCard(
              title: 'File Preview Panel',
              description: 'Show file browser panel on the right side of chat',
              child: _buildSwitch(
                value: settings.showFilePreview,
                onChanged: (v) => settings.setShowFilePreview(v),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Data Management'),
            const SizedBox(height: 24),

            _buildSettingCard(
              title: 'Clear All History',
              description: 'Delete all conversations and messages. This cannot be undone.',
              child: ElevatedButton(
                onPressed: () => _confirmClearHistory(context, settings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Clear History'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About'),
        const SizedBox(height: 24),

        _buildSettingCard(
          title: 'DeepClaude Desktop',
          description: 'A desktop client for Claude Code via ACP protocol',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Version', '1.0.0'),
              const SizedBox(height: 8),
              _buildInfoRow('Protocol', 'ACP (Agent Communication Protocol)'),
              const SizedBox(height: 8),
              _buildInfoRow('Platform', 'macOS / Windows / Linux'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1a1a1a),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFD97706),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1a1a1a),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDefaultDir(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final directory = await getDirectoryPath();
    if (directory != null) {
      await settings.setDefaultWorkingDir(directory);
    }
  }

  void _confirmClearHistory(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all conversations and messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.clearAllHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

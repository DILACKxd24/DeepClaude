import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'td_components.dart';

/// 文件预览面板
class FilePreviewPanel extends StatefulWidget {
  final String workingDir;
  final Function(String)? onFileSelected;

  const FilePreviewPanel({
    super.key,
    required this.workingDir,
    this.onFileSelected,
  });

  @override
  State<FilePreviewPanel> createState() => _FilePreviewPanelState();
}

class _FilePreviewPanelState extends State<FilePreviewPanel> {
  List<FileSystemEntity> _files = [];
  String? _selectedFilePath;
  String? _fileContent;
  bool _isLoading = false;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _currentPath = widget.workingDir;
    _loadFiles();
  }

  @override
  void didUpdateWidget(FilePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workingDir != widget.workingDir) {
      _currentPath = widget.workingDir;
      _loadFiles();
    }
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    try {
      final dir = Directory(_currentPath);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        entities.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.compareTo(b.path);
        });

        setState(() {
          _files = entities.where((e) {
            final name = e.path.split('/').last;
            return !name.startsWith('.');
          }).toList();
        });
      }
    } catch (e) {
      print('加载文件列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFileContent(String path) async {
    setState(() {
      _selectedFilePath = path;
      _isLoading = true;
    });

    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() => _fileContent = content);
      }
    } catch (e) {
      setState(() => _fileContent = '无法读取文件: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDirectory(String path) {
    setState(() {
      _currentPath = path;
      _selectedFilePath = null;
      _fileContent = null;
    });
    _loadFiles();
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent.path;
    if (parent.startsWith(widget.workingDir) || parent == widget.workingDir) {
      _navigateToDirectory(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: TDColors.getBgContainer(isDark),
        border: Border(
          left: BorderSide(color: TDColors.getBorder(isDark)),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildPathBar(),
          Expanded(
            child: _selectedFilePath != null
                ? _buildFilePreview()
                : _buildFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TDColors.getBorder(isDark)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_open_rounded, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Files',
              style: TextStyle(
                color: TDColors.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (_selectedFilePath != null)
            TDTooltipButton(
              icon: Icons.close,
              tooltip: 'Close preview',
              size: 28,
              onTap: () {
                setState(() {
                  _selectedFilePath = null;
                  _fileContent = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relativePath = _currentPath.replaceFirst(widget.workingDir, '');
    final displayPath = relativePath.isEmpty ? '/' : relativePath;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TDColors.getBgComponent(isDark),
        border: Border(
          bottom: BorderSide(color: TDColors.getBorder(isDark)),
        ),
      ),
      child: Row(
        children: [
          if (_currentPath != widget.workingDir)
            TDTooltipButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Go back',
              size: 28,
              onTap: _navigateUp,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TDColors.getBgContainer(isDark),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TDColors.getBorder(isDark)),
              ),
              child: Text(
                displayPath,
                style: TextStyle(
                  color: TDColors.getTextSecondary(isDark),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TDTooltipButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            size: 28,
            onTap: _loadFiles,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: TDLoadingIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_files.isEmpty) {
      return TDEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Empty folder',
        description: 'No files in this directory',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final entity = _files[index];
        final isDir = entity is Directory;
        final name = entity.path.split('/').last;

        return _FileListTile(
          name: name,
          isDirectory: isDir,
          onTap: () {
            if (isDir) {
              _navigateToDirectory(entity.path);
            } else {
              _loadFileContent(entity.path);
              widget.onFileSelected?.call(entity.path);
            }
          },
        );
      },
    );
  }

  Widget _buildFilePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: TDLoadingIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final fileName = _selectedFilePath?.split('/').last ?? '';
    final isMarkdown = fileName.endsWith('.md');

    return Column(
      children: [
        // 文件名
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TDColors.getBgComponent(isDark),
            border: Border(
              bottom: BorderSide(color: TDColors.getBorder(isDark)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getFileColor(fileName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  size: 14,
                  color: _getFileColor(fileName),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: TextStyle(
                    color: TDColors.getTextPrimary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 文件内容
        Expanded(
          child: _fileContent == null
              ? TDEmptyState(
                  icon: Icons.error_outline,
                  title: 'Cannot load file',
                )
              : isMarkdown
                  ? Markdown(
                      data: _fileContent!,
                      padding: const EdgeInsets.all(16),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: TDColors.getTextPrimary(isDark),
                          fontSize: 13,
                          height: 1.6,
                        ),
                        code: TextStyle(
                          backgroundColor: TDColors.getBgComponent(isDark),
                          color: TDColors.successColor,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: TDColors.getBgComponent(isDark),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _fileContent!,
                        style: TextStyle(
                          color: TDColors.getTextPrimary(isDark),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.dart')) return Icons.code;
    if (fileName.endsWith('.js') || fileName.endsWith('.ts')) return Icons.javascript;
    if (fileName.endsWith('.py')) return Icons.code;
    if (fileName.endsWith('.md')) return Icons.description;
    if (fileName.endsWith('.json')) return Icons.data_object;
    if (fileName.endsWith('.yaml') || fileName.endsWith('.yml')) return Icons.settings;
    if (fileName.endsWith('.html')) return Icons.html;
    if (fileName.endsWith('.css')) return Icons.css;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileName) {
    if (fileName.endsWith('.dart')) return const Color(0xFF0175C2);
    if (fileName.endsWith('.js')) return const Color(0xFFF7DF1E);
    if (fileName.endsWith('.ts')) return const Color(0xFF3178C6);
    if (fileName.endsWith('.py')) return const Color(0xFF3776AB);
    if (fileName.endsWith('.md')) return TDColors.textSecondary;
    if (fileName.endsWith('.json')) return TDColors.warningColor;
    return TDColors.textSecondary;
  }
}

class _FileListTile extends StatefulWidget {
  final String name;
  final bool isDirectory;
  final VoidCallback onTap;

  const _FileListTile({
    required this.name,
    required this.isDirectory,
    required this.onTap,
  });

  @override
  State<_FileListTile> createState() => _FileListTileState();
}

class _FileListTileState extends State<_FileListTile> {
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? TDColors.getBgComponentHover(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isDirectory 
                      ? accentColor.withOpacity(0.1)
                      : TDColors.getBgComponent(isDark),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  widget.isDirectory ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
                  size: 14,
                  color: widget.isDirectory ? accentColor : TDColors.getTextSecondary(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    color: TDColors.getTextPrimary(isDark),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isDirectory)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: TDColors.getTextPlaceholder(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

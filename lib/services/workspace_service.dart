import 'dart:io';

/// 工作区服务 - 管理 .deepclaude 目录和会话工作目录
class WorkspaceService {
  static WorkspaceService? _instance;
  static WorkspaceService get instance => _instance ??= WorkspaceService._();

  WorkspaceService._();

  /// 获取用户主目录
  String get homeDir {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) return home;
    // 备用
    if (Platform.isMacOS || Platform.isLinux) {
      return '/tmp';
    }
    return 'C:\\temp';
  }

  /// 获取 .deepclaude 根目录
  String get deepClaudeDir => '$homeDir/.deepclaude';

  /// 获取会话目录（存放所有会话的工作目录）
  String get sessionsDir => '$deepClaudeDir/sessions';

  /// 初始化 .deepclaude 目录结构
  Future<void> initialize() async {
    final dir = Directory(deepClaudeDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('[WorkspaceService] Created .deepclaude directory: $deepClaudeDir');
    }

    final sessions = Directory(sessionsDir);
    if (!await sessions.exists()) {
      await sessions.create(recursive: true);
      print('[WorkspaceService] Created sessions directory: $sessionsDir');
    }
  }

  /// 创建新的会话工作目录（使用时间戳命名）
  Future<String> createSessionWorkingDir({String? customName}) async {
    await initialize();

    // 生成时间戳目录名
    final now = DateTime.now();
    final timestamp = '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final dirName = customName ?? 'session_$timestamp';
    final sessionDir = '$sessionsDir/$dirName';

    final dir = Directory(sessionDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('[WorkspaceService] Created session directory: $sessionDir');
    }

    return sessionDir;
  }

  /// 获取所有会话目录
  Future<List<String>> listSessionDirs() async {
    await initialize();

    final sessions = Directory(sessionsDir);
    if (!await sessions.exists()) {
      return [];
    }

    final dirs = <String>[];
    await for (final entity in sessions.list()) {
      if (entity is Directory) {
        dirs.add(entity.path);
      }
    }

    // 按名称排序（时间戳命名，所以按字母排序即可）
    dirs.sort((a, b) => b.compareTo(a)); // 降序，最新的在前
    return dirs;
  }

  /// 删除会话目录
  Future<void> deleteSessionDir(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      print('[WorkspaceService] Deleted session directory: $path');
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

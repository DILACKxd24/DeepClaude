import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';

/// 主题模式
enum ThemeMode { light, dark, system }

/// 通知设置
class NotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool showPreview;
  final bool taskComplete;
  final bool errorAlert;

  NotificationSettings({
    this.enabled = true,
    this.soundEnabled = true,
    this.showPreview = true,
    this.taskComplete = true,
    this.errorAlert = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'soundEnabled': soundEnabled,
    'showPreview': showPreview,
    'taskComplete': taskComplete,
    'errorAlert': errorAlert,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      showPreview: json['showPreview'] ?? true,
      taskComplete: json['taskComplete'] ?? true,
      errorAlert: json['errorAlert'] ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? showPreview,
    bool? taskComplete,
    bool? errorAlert,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showPreview: showPreview ?? this.showPreview,
      taskComplete: taskComplete ?? this.taskComplete,
      errorAlert: errorAlert ?? this.errorAlert,
    );
  }
}

/// 快捷键配置
class KeyboardShortcuts {
  final String newChat;
  final String search;
  final String settings;
  final String toggleSidebar;
  final String sendMessage;

  KeyboardShortcuts({
    this.newChat = '⌘ N',
    this.search = '⌘ K',
    this.settings = '⌘ ,',
    this.toggleSidebar = '⌘ B',
    this.sendMessage = '⌘ Enter',
  });

  Map<String, dynamic> toJson() => {
    'newChat': newChat,
    'search': search,
    'settings': settings,
    'toggleSidebar': toggleSidebar,
    'sendMessage': sendMessage,
  };

  factory KeyboardShortcuts.fromJson(Map<String, dynamic> json) {
    return KeyboardShortcuts(
      newChat: json['newChat'] ?? '⌘ N',
      search: json['search'] ?? '⌘ K',
      settings: json['settings'] ?? '⌘ ,',
      toggleSidebar: json['toggleSidebar'] ?? '⌘ B',
      sendMessage: json['sendMessage'] ?? '⌘ Enter',
    );
  }
}

/// 用户配置文件
class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final String? apiKey;

  UserProfile({
    this.name = 'User',
    this.email = '',
    this.avatarUrl = '',
    this.apiKey,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'apiKey': apiKey,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      apiKey: json['apiKey'],
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? apiKey,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  // 基础设置
  String _defaultWorkingDir = '';
  bool _autoApproveRead = false;
  bool _autoApproveWrite = false;
  bool _autoApproveExecute = false;
  double _fontSize = 14.0;
  bool _showFilePreview = false;
  
  // 外观设置
  ThemeMode _themeMode = ThemeMode.system;
  String _accentColor = '#D97706';
  bool _compactMode = false;
  bool _showLineNumbers = true;
  String _codeFont = 'JetBrains Mono';
  
  // 编辑器设置
  bool _autoSave = true;
  int _autoSaveInterval = 30; // 秒
  bool _wordWrap = true;
  int _tabSize = 2;
  
  // 通知设置
  NotificationSettings _notifications = NotificationSettings();
  
  // 快捷键设置
  KeyboardShortcuts _shortcuts = KeyboardShortcuts();
  
  // 用户配置
  UserProfile _userProfile = UserProfile();
  
  // 高级设置
  bool _enableTelemetry = false;
  bool _enableBetaFeatures = false;
  int _maxHistoryItems = 100;
  bool _confirmBeforeDelete = true;
  bool _showHiddenFiles = false;
  
  // 网络设置
  String _proxyUrl = '';
  int _requestTimeout = 60; // 秒
  bool _useProxy = false;

  // Getters
  String get defaultWorkingDir => _defaultWorkingDir;
  bool get autoApproveRead => _autoApproveRead;
  bool get autoApproveWrite => _autoApproveWrite;
  bool get autoApproveExecute => _autoApproveExecute;
  double get fontSize => _fontSize;
  bool get showFilePreview => _showFilePreview;
  ThemeMode get themeMode => _themeMode;
  String get accentColor => _accentColor;
  bool get compactMode => _compactMode;
  bool get showLineNumbers => _showLineNumbers;
  String get codeFont => _codeFont;
  bool get autoSave => _autoSave;
  int get autoSaveInterval => _autoSaveInterval;
  bool get wordWrap => _wordWrap;
  int get tabSize => _tabSize;
  NotificationSettings get notifications => _notifications;
  KeyboardShortcuts get shortcuts => _shortcuts;
  UserProfile get userProfile => _userProfile;
  bool get enableTelemetry => _enableTelemetry;
  bool get enableBetaFeatures => _enableBetaFeatures;
  int get maxHistoryItems => _maxHistoryItems;
  bool get confirmBeforeDelete => _confirmBeforeDelete;
  bool get showHiddenFiles => _showHiddenFiles;
  String get proxyUrl => _proxyUrl;
  int get requestTimeout => _requestTimeout;
  bool get useProxy => _useProxy;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 基础设置
    _defaultWorkingDir = prefs.getString('defaultWorkingDir') ?? '';
    _autoApproveRead = prefs.getBool('autoApproveRead') ?? false;
    _autoApproveWrite = prefs.getBool('autoApproveWrite') ?? false;
    _autoApproveExecute = prefs.getBool('autoApproveExecute') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 14.0;
    _showFilePreview = prefs.getBool('showFilePreview') ?? false;
    
    // 外观设置
    final themeModeIndex = prefs.getInt('themeMode') ?? 2;
    _themeMode = ThemeMode.values[themeModeIndex];
    _accentColor = prefs.getString('accentColor') ?? '#D97706';
    _compactMode = prefs.getBool('compactMode') ?? false;
    _showLineNumbers = prefs.getBool('showLineNumbers') ?? true;
    _codeFont = prefs.getString('codeFont') ?? 'JetBrains Mono';
    
    // 编辑器设置
    _autoSave = prefs.getBool('autoSave') ?? true;
    _autoSaveInterval = prefs.getInt('autoSaveInterval') ?? 30;
    _wordWrap = prefs.getBool('wordWrap') ?? true;
    _tabSize = prefs.getInt('tabSize') ?? 2;
    
    // 通知设置
    final notificationsJson = prefs.getString('notifications');
    if (notificationsJson != null) {
      _notifications = NotificationSettings.fromJson(jsonDecode(notificationsJson));
    }
    
    // 快捷键设置
    final shortcutsJson = prefs.getString('shortcuts');
    if (shortcutsJson != null) {
      _shortcuts = KeyboardShortcuts.fromJson(jsonDecode(shortcutsJson));
    }
    
    // 用户配置
    final userProfileJson = prefs.getString('userProfile');
    if (userProfileJson != null) {
      _userProfile = UserProfile.fromJson(jsonDecode(userProfileJson));
    }
    
    // 高级设置
    _enableTelemetry = prefs.getBool('enableTelemetry') ?? false;
    _enableBetaFeatures = prefs.getBool('enableBetaFeatures') ?? false;
    _maxHistoryItems = prefs.getInt('maxHistoryItems') ?? 100;
    _confirmBeforeDelete = prefs.getBool('confirmBeforeDelete') ?? true;
    _showHiddenFiles = prefs.getBool('showHiddenFiles') ?? false;
    
    // 网络设置
    _proxyUrl = prefs.getString('proxyUrl') ?? '';
    _requestTimeout = prefs.getInt('requestTimeout') ?? 60;
    _useProxy = prefs.getBool('useProxy') ?? false;
    
    notifyListeners();
  }

  // 基础设置方法
  Future<void> setDefaultWorkingDir(String dir) async {
    _defaultWorkingDir = dir;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultWorkingDir', dir);
    notifyListeners();
  }

  Future<void> setAutoApproveRead(bool value) async {
    _autoApproveRead = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoApproveRead', value);
    notifyListeners();
  }

  Future<void> setAutoApproveWrite(bool value) async {
    _autoApproveWrite = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoApproveWrite', value);
    notifyListeners();
  }

  Future<void> setAutoApproveExecute(bool value) async {
    _autoApproveExecute = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoApproveExecute', value);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setShowFilePreview(bool value) async {
    _showFilePreview = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFilePreview', value);
    notifyListeners();
  }

  void toggleFilePreview() {
    setShowFilePreview(!_showFilePreview);
  }

  // 外观设置方法
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(String color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', color);
    notifyListeners();
  }

  Future<void> setCompactMode(bool value) async {
    _compactMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('compactMode', value);
    notifyListeners();
  }

  Future<void> setShowLineNumbers(bool value) async {
    _showLineNumbers = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showLineNumbers', value);
    notifyListeners();
  }

  Future<void> setCodeFont(String font) async {
    _codeFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeFont', font);
    notifyListeners();
  }

  // 编辑器设置方法
  Future<void> setAutoSave(bool value) async {
    _autoSave = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSave', value);
    notifyListeners();
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    _autoSaveInterval = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoSaveInterval', seconds);
    notifyListeners();
  }

  Future<void> setWordWrap(bool value) async {
    _wordWrap = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wordWrap', value);
    notifyListeners();
  }

  Future<void> setTabSize(int size) async {
    _tabSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tabSize', size);
    notifyListeners();
  }

  // 通知设置方法
  Future<void> setNotifications(NotificationSettings settings) async {
    _notifications = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(settings.toJson()));
    notifyListeners();
  }

  // 快捷键设置方法
  Future<void> setShortcuts(KeyboardShortcuts shortcuts) async {
    _shortcuts = shortcuts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shortcuts', jsonEncode(shortcuts.toJson()));
    notifyListeners();
  }

  // 用户配置方法
  Future<void> setUserProfile(UserProfile profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', jsonEncode(profile.toJson()));
    notifyListeners();
  }

  // 高级设置方法
  Future<void> setEnableTelemetry(bool value) async {
    _enableTelemetry = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableTelemetry', value);
    notifyListeners();
  }

  Future<void> setEnableBetaFeatures(bool value) async {
    _enableBetaFeatures = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableBetaFeatures', value);
    notifyListeners();
  }

  Future<void> setMaxHistoryItems(int count) async {
    _maxHistoryItems = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxHistoryItems', count);
    notifyListeners();
  }

  Future<void> setConfirmBeforeDelete(bool value) async {
    _confirmBeforeDelete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('confirmBeforeDelete', value);
    notifyListeners();
  }

  Future<void> setShowHiddenFiles(bool value) async {
    _showHiddenFiles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showHiddenFiles', value);
    notifyListeners();
  }

  // 网络设置方法
  Future<void> setProxyUrl(String url) async {
    _proxyUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proxyUrl', url);
    notifyListeners();
  }

  Future<void> setRequestTimeout(int seconds) async {
    _requestTimeout = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('requestTimeout', seconds);
    notifyListeners();
  }

  Future<void> setUseProxy(bool value) async {
    _useProxy = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useProxy', value);
    notifyListeners();
  }

  // 数据管理方法
  Future<void> clearAllHistory() async {
    await StorageService.instance.saveConversations([]);
    notifyListeners();
  }

  /// 导出设置到文件
  Future<String?> exportSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{
        'defaultWorkingDir': _defaultWorkingDir,
        'autoApproveRead': _autoApproveRead,
        'autoApproveWrite': _autoApproveWrite,
        'autoApproveExecute': _autoApproveExecute,
        'fontSize': _fontSize,
        'showFilePreview': _showFilePreview,
        'themeMode': _themeMode.index,
        'accentColor': _accentColor,
        'compactMode': _compactMode,
        'showLineNumbers': _showLineNumbers,
        'codeFont': _codeFont,
        'autoSave': _autoSave,
        'autoSaveInterval': _autoSaveInterval,
        'wordWrap': _wordWrap,
        'tabSize': _tabSize,
        'notifications': _notifications.toJson(),
        'shortcuts': _shortcuts.toJson(),
        'userProfile': _userProfile.toJson(),
        'enableTelemetry': _enableTelemetry,
        'enableBetaFeatures': _enableBetaFeatures,
        'maxHistoryItems': _maxHistoryItems,
        'confirmBeforeDelete': _confirmBeforeDelete,
        'showHiddenFiles': _showHiddenFiles,
        'proxyUrl': _proxyUrl,
        'requestTimeout': _requestTimeout,
        'useProxy': _useProxy,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      final appDir = await getApplicationDocumentsDirectory();
      final exportFile = File('${appDir.path}/deepclaude_settings_export.json');
      await exportFile.writeAsString(const JsonEncoder.withIndent('  ').convert(settings));
      return exportFile.path;
    } catch (e) {
      print('导出设置失败: $e');
      return null;
    }
  }

  /// 从文件导入设置
  Future<bool> importSettings(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final content = await file.readAsString();
      final settings = jsonDecode(content) as Map<String, dynamic>;
      
      // 应用设置
      if (settings['defaultWorkingDir'] != null) {
        await setDefaultWorkingDir(settings['defaultWorkingDir']);
      }
      if (settings['autoApproveRead'] != null) {
        await setAutoApproveRead(settings['autoApproveRead']);
      }
      if (settings['autoApproveWrite'] != null) {
        await setAutoApproveWrite(settings['autoApproveWrite']);
      }
      if (settings['autoApproveExecute'] != null) {
        await setAutoApproveExecute(settings['autoApproveExecute']);
      }
      if (settings['fontSize'] != null) {
        await setFontSize(settings['fontSize'].toDouble());
      }
      if (settings['showFilePreview'] != null) {
        await setShowFilePreview(settings['showFilePreview']);
      }
      if (settings['themeMode'] != null) {
        await setThemeMode(ThemeMode.values[settings['themeMode']]);
      }
      if (settings['accentColor'] != null) {
        await setAccentColor(settings['accentColor']);
      }
      if (settings['compactMode'] != null) {
        await setCompactMode(settings['compactMode']);
      }
      if (settings['notifications'] != null) {
        await setNotifications(NotificationSettings.fromJson(settings['notifications']));
      }
      if (settings['shortcuts'] != null) {
        await setShortcuts(KeyboardShortcuts.fromJson(settings['shortcuts']));
      }
      if (settings['userProfile'] != null) {
        await setUserProfile(UserProfile.fromJson(settings['userProfile']));
      }
      
      return true;
    } catch (e) {
      print('导入设置失败: $e');
      return false;
    }
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _defaultWorkingDir = '';
    _autoApproveRead = false;
    _autoApproveWrite = false;
    _autoApproveExecute = false;
    _fontSize = 14.0;
    _showFilePreview = false;
    _themeMode = ThemeMode.system;
    _accentColor = '#D97706';
    _compactMode = false;
    _showLineNumbers = true;
    _codeFont = 'JetBrains Mono';
    _autoSave = true;
    _autoSaveInterval = 30;
    _wordWrap = true;
    _tabSize = 2;
    _notifications = NotificationSettings();
    _shortcuts = KeyboardShortcuts();
    _userProfile = UserProfile();
    _enableTelemetry = false;
    _enableBetaFeatures = false;
    _maxHistoryItems = 100;
    _confirmBeforeDelete = true;
    _showHiddenFiles = false;
    _proxyUrl = '';
    _requestTimeout = 60;
    _useProxy = false;
    
    notifyListeners();
  }
}

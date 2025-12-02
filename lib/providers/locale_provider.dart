import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言
enum AppLanguage {
  english('en', 'English'),
  chinese('zh', '中文'),
  japanese('ja', '日本語');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// 多语言文本
class AppStrings {
  // Settings
  static String settings(AppLanguage lang) => _t(lang, 'Settings', '设置', '設定');
  static String general(AppLanguage lang) => _t(lang, 'General', '通用', '一般');
  static String account(AppLanguage lang) => _t(lang, 'Account', '账户', 'アカウント');
  static String privacy(AppLanguage lang) => _t(lang, 'Privacy', '隐私', 'プライバシー');
  static String claudeCode(AppLanguage lang) => _t(lang, 'DeepClaude', 'DeepClaude', 'DeepClaude');
  static String model(AppLanguage lang) => _t(lang, 'Model', '模型', 'モデル');
  static String desktopApp(AppLanguage lang) => _t(lang, 'Desktop app', '桌面应用', 'デスクトップアプリ');
  static String extensions(AppLanguage lang) => _t(lang, 'Extensions', '扩展', '拡張機能');
  static String developer(AppLanguage lang) => _t(lang, 'Developer', '开发者', '開発者');
  
  // General Section
  static String language(AppLanguage lang) => _t(lang, 'Language', '语言', '言語');
  static String languageDesc(AppLanguage lang) => _t(lang, 'Select your preferred language', '选择您的首选语言', '言語を選択');
  static String defaultWorkingDir(AppLanguage lang) => _t(lang, 'Default Working Directory', '默认工作目录', 'デフォルト作業ディレクトリ');
  static String defaultWorkingDirDesc(AppLanguage lang) => _t(lang, 'Set the default directory for new conversations', '设置新会话的默认目录', '新しい会話のデフォルトディレクトリを設定');
  static String browse(AppLanguage lang) => _t(lang, 'Browse', '浏览', '参照');
  static String notSet(AppLanguage lang) => _t(lang, 'Not set', '未设置', '未設定');

  // Account Section
  static String profile(AppLanguage lang) => _t(lang, 'Profile', '个人资料', 'プロフィール');
  static String profileDesc(AppLanguage lang) => _t(lang, 'Your account information', '您的账户信息', 'アカウント情報');
  static String username(AppLanguage lang) => _t(lang, 'Username', '用户名', 'ユーザー名');
  static String email(AppLanguage lang) => _t(lang, 'Email', '邮箱', 'メール');

  // Privacy Section
  static String dataCollection(AppLanguage lang) => _t(lang, 'Data Collection', '数据收集', 'データ収集');
  static String dataCollectionDesc(AppLanguage lang) => _t(lang, 'Help improve DeepClaude by sending anonymous usage data', '发送匿名使用数据以帮助改进 DeepClaude', '匿名の使用データを送信してDeepClaudeの改善に協力');
  static String clearHistory(AppLanguage lang) => _t(lang, 'Clear History', '清除历史', '履歴をクリア');
  static String clearHistoryDesc(AppLanguage lang) => _t(lang, 'Delete all conversations and messages', '删除所有会话和消息', 'すべての会話とメッセージを削除');
  static String clearHistoryBtn(AppLanguage lang) => _t(lang, 'Clear All', '全部清除', 'すべてクリア');

  // Claude Code Section
  static String aiProvider(AppLanguage lang) => _t(lang, 'AI Provider', 'AI 供应商', 'AIプロバイダー');
  static String aiProviderDesc(AppLanguage lang) => _t(lang, 'Configure the AI provider and model', '配置 AI 供应商和模型', 'AIプロバイダーとモデルを設定');
  static String defaultModel(AppLanguage lang) => _t(lang, 'Default model', '默认模型', 'デフォルトモデル');

  // Appearance Section
  static String appearance(AppLanguage lang) => _t(lang, 'Appearance', '外观', '外観');
  static String theme(AppLanguage lang) => _t(lang, 'Theme', '主题', 'テーマ');
  static String themeDesc(AppLanguage lang) => _t(lang, 'Choose your preferred color theme', '选择您喜欢的颜色主题', 'お好みのカラーテーマを選択');
  static String light(AppLanguage lang) => _t(lang, 'Light', '浅色', 'ライト');
  static String dark(AppLanguage lang) => _t(lang, 'Dark', '深色', 'ダーク');
  static String system(AppLanguage lang) => _t(lang, 'System', '跟随系统', 'システム');
  static String fontSize(AppLanguage lang) => _t(lang, 'Font Size', '字体大小', 'フォントサイズ');
  static String fontSizeDesc(AppLanguage lang) => _t(lang, 'Adjust the chat font size', '调整聊天字体大小', 'チャットのフォントサイズを調整');
  static String filePreview(AppLanguage lang) => _t(lang, 'File Preview Panel', '文件预览面板', 'ファイルプレビューパネル');
  static String filePreviewDesc(AppLanguage lang) => _t(lang, 'Show file browser on the right', '在右侧显示文件浏览器', '右側にファイルブラウザを表示');

  // Permissions Section
  static String permissions(AppLanguage lang) => _t(lang, 'Permissions', '权限', '権限');
  static String autoApproveRead(AppLanguage lang) => _t(lang, 'Auto-approve File Read', '自动允许读取文件', 'ファイル読み取りを自動承認');
  static String autoApproveReadDesc(AppLanguage lang) => _t(lang, 'Allow Claude to read files without asking', '允许 Claude 无需询问即可读取文件', 'Claudeが確認なしでファイルを読み取ることを許可');
  static String autoApproveWrite(AppLanguage lang) => _t(lang, 'Auto-approve File Write', '自动允许写入文件', 'ファイル書き込みを自動承認');
  static String autoApproveWriteDesc(AppLanguage lang) => _t(lang, 'Allow Claude to write files (use with caution)', '允许 Claude 写入文件（谨慎使用）', 'Claudeがファイルを書き込むことを許可（注意して使用）');

  // Developer Section
  static String debugMode(AppLanguage lang) => _t(lang, 'Debug Mode', '调试模式', 'デバッグモード');
  static String debugModeDesc(AppLanguage lang) => _t(lang, 'Show detailed logs and debug information', '显示详细日志和调试信息', '詳細なログとデバッグ情報を表示');
  static String version(AppLanguage lang) => _t(lang, 'Version', '版本', 'バージョン');
  static String checkUpdates(AppLanguage lang) => _t(lang, 'Check for Updates', '检查更新', 'アップデートを確認');

  // Common
  static String cancel(AppLanguage lang) => _t(lang, 'Cancel', '取消', 'キャンセル');
  static String save(AppLanguage lang) => _t(lang, 'Save', '保存', '保存');
  static String add(AppLanguage lang) => _t(lang, 'Add', '添加', '追加');
  static String edit(AppLanguage lang) => _t(lang, 'Edit', '编辑', '編集');
  static String delete(AppLanguage lang) => _t(lang, 'Delete', '删除', '削除');
  static String back(AppLanguage lang) => _t(lang, 'Back', '返回', '戻る');
  static String confirm(AppLanguage lang) => _t(lang, 'Confirm', '确认', '確認');

  static String _t(AppLanguage lang, String en, String zh, String ja) {
    switch (lang) {
      case AppLanguage.english:
        return en;
      case AppLanguage.chinese:
        return zh;
      case AppLanguage.japanese:
        return ja;
    }
  }
}

/// 语言管理 Provider
class LocaleProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  bool _debugMode = false;
  bool _dataCollection = true;
  String _theme = 'system'; // light, dark, system

  AppLanguage get language => _language;
  bool get debugMode => _debugMode;
  bool get dataCollection => _dataCollection;
  String get theme => _theme;

  LocaleProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    _language = AppLanguage.fromCode(langCode);
    _debugMode = prefs.getBool('debugMode') ?? false;
    _dataCollection = prefs.getBool('dataCollection') ?? true;
    _theme = prefs.getString('theme') ?? 'system';
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang.code);
    notifyListeners();
  }

  Future<void> setDebugMode(bool value) async {
    _debugMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debugMode', value);
    notifyListeners();
  }

  Future<void> setDataCollection(bool value) async {
    _dataCollection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dataCollection', value);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    _theme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value);
    notifyListeners();
  }
}

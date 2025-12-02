import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/provider_config.dart';

/// 供应商管理器
class ProviderManager extends ChangeNotifier {
  List<ProviderConfig> _providers = [];
  ProviderConfig? _currentProvider;
  bool _isLoading = false;

  List<ProviderConfig> get providers => _providers;
  ProviderConfig? get currentProvider => _currentProvider;
  bool get isLoading => _isLoading;

  ProviderManager() {
    _loadProviders();
  }

  /// 加载供应商配置
  Future<void> _loadProviders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final configFile = await _getConfigFile();
      
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        final providersList = (data['providers'] as List?)
            ?.map((p) => ProviderConfig.fromJson(p))
            .toList() ?? [];
        
        _providers = [...providerPresets, ...providersList];
        
        final currentId = data['currentProviderId'] as String?;
        if (currentId != null) {
          _currentProvider = _providers.firstWhere(
            (p) => p.id == currentId,
            orElse: () => _providers.first,
          );
        }
      } else {
        _providers = [...providerPresets];
        _currentProvider = _providers.first;
      }
    } catch (e) {
      print('加载供应商配置失败: $e');
      _providers = [...providerPresets];
      _currentProvider = _providers.first;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 保存供应商配置
  Future<void> _saveProviders() async {
    try {
      final configFile = await _getConfigFile();
      
      // 只保存自定义供应商（非预设）
      final customProviders = _providers
          .where((p) => !providerPresets.any((preset) => preset.id == p.id))
          .map((p) => p.toJson())
          .toList();
      
      final data = {
        'providers': customProviders,
        'currentProviderId': _currentProvider?.id,
      };
      
      await configFile.writeAsString(jsonEncode(data));
    } catch (e) {
      print('保存供应商配置失败: $e');
    }
  }

  /// 获取配置文件
  Future<File> _getConfigFile() async {
    final appDir = await getApplicationSupportDirectory();
    final configDir = Directory('${appDir.path}/claude_code_desktop');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return File('${configDir.path}/providers.json');
  }

  /// 设置当前供应商
  Future<void> setCurrentProvider(ProviderConfig provider) async {
    _currentProvider = provider;
    notifyListeners();
    await _saveProviders();
    
    // 应用环境变量到 Claude Code 配置
    await _applyProviderConfig(provider);
  }

  /// 添加自定义供应商
  Future<void> addProvider(ProviderConfig provider) async {
    _providers.add(provider);
    notifyListeners();
    await _saveProviders();
  }

  /// 更新供应商
  Future<void> updateProvider(ProviderConfig provider) async {
    final index = _providers.indexWhere((p) => p.id == provider.id);
    if (index >= 0) {
      _providers[index] = provider;
      if (_currentProvider?.id == provider.id) {
        _currentProvider = provider;
      }
      notifyListeners();
      await _saveProviders();
    }
  }

  /// 删除供应商
  Future<void> deleteProvider(String id) async {
    // 不能删除预设供应商
    if (providerPresets.any((p) => p.id == id)) return;
    
    _providers.removeWhere((p) => p.id == id);
    if (_currentProvider?.id == id) {
      _currentProvider = _providers.first;
    }
    notifyListeners();
    await _saveProviders();
  }

  /// 应用供应商配置到 DeepClaude
  Future<void> _applyProviderConfig(ProviderConfig provider) async {
    try {
      // 获取 DeepClaude 配置目录
      final homeDir = Platform.environment['HOME'] ?? '';
      final claudeConfigDir = Directory('$homeDir/.claude');
      
      if (!await claudeConfigDir.exists()) {
        await claudeConfigDir.create(recursive: true);
      }
      
      // 读取或创建 settings.json
      final settingsFile = File('${claudeConfigDir.path}/settings.json');
      Map<String, dynamic> settings = {};
      
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        settings = jsonDecode(content) as Map<String, dynamic>;
      }
      
      // 更新环境变量
      settings['env'] = provider.toEnvMap();
      
      // 写入配置
      await settingsFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(settings),
      );
      
      print('已应用供应商配置: ${provider.name}');
    } catch (e) {
      print('应用供应商配置失败: $e');
    }
  }

  /// 获取当前 DeepClaude 配置
  Future<Map<String, dynamic>?> getCurrentClaudeConfig() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final settingsFile = File('$homeDir/.claude/settings.json');
      
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      print('读取 Claude 配置失败: $e');
    }
    return null;
  }
}

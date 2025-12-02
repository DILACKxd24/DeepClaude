/// Claude Code 供应商配置

class ProviderConfig {
  final String id;
  final String name;
  final String? baseUrl;
  final String? authToken;
  final String? model;
  final String? haikuModel;
  final String? sonnetModel;
  final String? opusModel;
  final String? websiteUrl;
  final String? iconName;
  final String? iconColor;
  final bool isOfficial;

  ProviderConfig({
    required this.id,
    required this.name,
    this.baseUrl,
    this.authToken,
    this.model,
    this.haikuModel,
    this.sonnetModel,
    this.opusModel,
    this.websiteUrl,
    this.iconName,
    this.iconColor,
    this.isOfficial = false,
  });

  /// 转换为环境变量 Map
  Map<String, String> toEnvMap() {
    final env = <String, String>{};
    if (baseUrl != null && baseUrl!.isNotEmpty) {
      env['ANTHROPIC_BASE_URL'] = baseUrl!;
    }
    if (authToken != null && authToken!.isNotEmpty) {
      env['ANTHROPIC_AUTH_TOKEN'] = authToken!;
    }
    if (model != null && model!.isNotEmpty) {
      env['ANTHROPIC_MODEL'] = model!;
    }
    if (haikuModel != null && haikuModel!.isNotEmpty) {
      env['ANTHROPIC_DEFAULT_HAIKU_MODEL'] = haikuModel!;
    }
    if (sonnetModel != null && sonnetModel!.isNotEmpty) {
      env['ANTHROPIC_DEFAULT_SONNET_MODEL'] = sonnetModel!;
    }
    if (opusModel != null && opusModel!.isNotEmpty) {
      env['ANTHROPIC_DEFAULT_OPUS_MODEL'] = opusModel!;
    }
    return env;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'authToken': authToken,
      'model': model,
      'haikuModel': haikuModel,
      'sonnetModel': sonnetModel,
      'opusModel': opusModel,
      'websiteUrl': websiteUrl,
      'iconName': iconName,
      'iconColor': iconColor,
      'isOfficial': isOfficial,
    };
  }

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'],
      authToken: json['authToken'],
      model: json['model'],
      haikuModel: json['haikuModel'],
      sonnetModel: json['sonnetModel'],
      opusModel: json['opusModel'],
      websiteUrl: json['websiteUrl'],
      iconName: json['iconName'],
      iconColor: json['iconColor'],
      isOfficial: json['isOfficial'] ?? false,
    );
  }

  ProviderConfig copyWith({
    String? name,
    String? baseUrl,
    String? authToken,
    String? model,
    String? haikuModel,
    String? sonnetModel,
    String? opusModel,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
      model: model ?? this.model,
      haikuModel: haikuModel ?? this.haikuModel,
      sonnetModel: sonnetModel ?? this.sonnetModel,
      opusModel: opusModel ?? this.opusModel,
      websiteUrl: websiteUrl,
      iconName: iconName,
      iconColor: iconColor,
      isOfficial: isOfficial,
    );
  }
}

/// 预设供应商列表
final List<ProviderConfig> providerPresets = [
  ProviderConfig(
    id: 'claude_official',
    name: 'Claude Official',
    websiteUrl: 'https://www.anthropic.com/claude-code',
    isOfficial: true,
    iconName: 'anthropic',
    iconColor: '#D4915D',
  ),
  ProviderConfig(
    id: 'deepseek',
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/anthropic',
    model: 'DeepSeek-V3.2',
    haikuModel: 'DeepSeek-V3.2',
    sonnetModel: 'DeepSeek-V3.2',
    opusModel: 'DeepSeek-V3.2',
    websiteUrl: 'https://platform.deepseek.com',
    iconName: 'deepseek',
    iconColor: '#1E88E5',
  ),
  ProviderConfig(
    id: 'zhipu_glm',
    name: 'Zhipu GLM',
    baseUrl: 'https://open.bigmodel.cn/api/anthropic',
    model: 'glm-4.6',
    haikuModel: 'glm-4.5-air',
    sonnetModel: 'glm-4.6',
    opusModel: 'glm-4.6',
    websiteUrl: 'https://open.bigmodel.cn',
    iconName: 'zhipu',
    iconColor: '#0F62FE',
  ),
  ProviderConfig(
    id: 'qwen_coder',
    name: 'Qwen Coder',
    baseUrl: 'https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy',
    model: 'qwen3-max',
    haikuModel: 'qwen3-max',
    sonnetModel: 'qwen3-max',
    opusModel: 'qwen3-max',
    websiteUrl: 'https://bailian.console.aliyun.com',
    iconName: 'qwen',
    iconColor: '#FF6A00',
  ),
  ProviderConfig(
    id: 'kimi_k2',
    name: 'Kimi K2',
    baseUrl: 'https://api.moonshot.cn/anthropic',
    model: 'kimi-k2-thinking',
    haikuModel: 'kimi-k2-thinking',
    sonnetModel: 'kimi-k2-thinking',
    opusModel: 'kimi-k2-thinking',
    websiteUrl: 'https://platform.moonshot.cn/console',
    iconName: 'kimi',
    iconColor: '#6366F1',
  ),
  ProviderConfig(
    id: 'openrouter',
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'anthropic/claude-sonnet-4',
    haikuModel: 'anthropic/claude-3-5-haiku',
    sonnetModel: 'anthropic/claude-sonnet-4',
    opusModel: 'anthropic/claude-sonnet-4',
    websiteUrl: 'https://openrouter.ai',
    iconName: 'openrouter',
    iconColor: '#6366F1',
  ),
];

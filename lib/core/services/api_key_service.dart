import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:http/http.dart' as http;

/// API密钥信息
class ApiKeyInfo {
  final int id;
  final String? modelServiceType;
  final String? accessToken;
  final int? providerId;
  final String? description;

  ApiKeyInfo({
    required this.id,
    this.modelServiceType,
    this.accessToken,
    this.providerId,
    this.description,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final modelServiceType = json['model_service_type'];
    final accessToken = json['access_token'];
    final providerId = json['provider_id'];
    final description = json['description'];

    debugPrint('ApiKeyInfo.fromJson - ID: $id, Type: $modelServiceType, Provider: $providerId, HasToken: ${accessToken != null}');

    return ApiKeyInfo(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      modelServiceType: modelServiceType?.toString(),
      accessToken: accessToken?.toString(),
      providerId: providerId is int ? providerId : (providerId != null ? int.tryParse(providerId.toString()) : null),
      description: description?.toString(),
    );
  }

  /// 是否是同声传译类型的密钥
  bool get isSimultaneousInterpretation {
    if (modelServiceType == null) {
      return false;
    }

    final type = modelServiceType!.toLowerCase();
    debugPrint('ApiKeyInfo: 检查类型 "$type"');

    // 根据服务器配置，同声传译的 model_service_type 可能是：
    // 'voice', 'translation', 'simultaneous', 'interpretation' 等
    const simultaneousTypes = [
      'voice',
      'translation',
      'simultaneous',
      'interpretation',
      'simultaneous_interpretation',
      'asr',  // 自动语音识别
      'tts',  // 语音合成
    ];

    final result = simultaneousTypes.any((simultaneousType) => type.contains(simultaneousType));
    debugPrint('ApiKeyInfo: 类型 "$type" ${result ? "匹配" : "不匹配"} 同声传译');
    return result;
  }

  @override
  String toString() {
    return 'ApiKeyInfo(id: $id, type: $modelServiceType, provider: $providerId)';
  }
}

/// API密钥服务
/// 负责获取和管理API密钥信息
class ApiKeyService {
  String? _authToken;

  /// 设置认证Token
  void setAuthToken(String token) {
    _authToken = token;
    debugPrint('ApiKeyService: 已设置认证Token');
  }

  /// 获取API密钥列表
  Future<List<ApiKeyInfo>> getApiKeys() async {
    try {
      if (_authToken == null || _authToken!.isEmpty) {
        debugPrint('ApiKeyService: 未设置认证Token');
        return [];
      }

      debugPrint('ApiKeyService: 正在获取API密钥列表...');
      final url = Uri.parse(AppConfig.getApiPath('/llm/api-keys'));

      debugPrint('ApiKeyService: 请求URL - $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('ApiKeyService: 响应状态码 - ${response.statusCode}');
      debugPrint('ApiKeyService: 响应体 - ${response.body}');

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        debugPrint('ApiKeyService: 解析后的响应 - ${jsonEncode(responseJson)}');

        // 检查响应格式
        if (responseJson is Map) {
          // 检查是否有 data.data.items 结构
          if (responseJson.containsKey('data')) {
            final data = responseJson['data'];
            if (data is Map && data.containsKey('items')) {
              final items = data['items'] as List;
              final apiKeys = items
                  .map((item) => ApiKeyInfo.fromJson(item))
                  .toList();

              debugPrint('ApiKeyService: 获取到 ${apiKeys.length} 个API密钥');
              for (var key in apiKeys) {
                debugPrint('  - ID: ${key.id}, Type: ${key.modelServiceType}, Provider: ${key.providerId}, HasToken: ${key.accessToken != null}');
              }

              return apiKeys;
            }
          }
          // 备用：直接检查 items 字段
          else if (responseJson.containsKey('items')) {
            final items = responseJson['items'] as List;
            final apiKeys = items
                .map((item) => ApiKeyInfo.fromJson(item))
                .toList();

            debugPrint('ApiKeyService: 获取到 ${apiKeys.length} 个API密钥');
            for (var key in apiKeys) {
              debugPrint('  - ID: ${key.id}, Type: ${key.modelServiceType}, Provider: ${key.providerId}, HasToken: ${key.accessToken != null}');
            }

            return apiKeys;
          }
        }

        debugPrint('ApiKeyService: 响应格式错误，没有找到items字段');
      } else {
        debugPrint('ApiKeyService: 获取API密钥失败 - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiKeyService: 获取API密钥异常 - $e');
      debugPrint('ApiKeyService: 堆栈 - ${StackTrace.current}');
    }

    return [];
  }

  /// 获取同声传译类型的API密钥
  Future<ApiKeyInfo?> getSimultaneousInterpretationKey() async {
    final apiKeys = await getApiKeys();

    // 查找同声传译类型的密钥
    for (var key in apiKeys) {
      if (key.isSimultaneousInterpretation) {
        debugPrint('ApiKeyService: 找到同声传译密钥 - $key');
        return key;
      }
    }

    debugPrint('ApiKeyService: 未找到同声传译类型的API密钥');
    return null;
  }
}

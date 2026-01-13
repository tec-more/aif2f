# 智谱AI集成 - 故障排除指南

## 常见问题和解决方案

### ❌ 问题1: 网络连接错误 "api.openai.com"

**错误信息:**
```
DioException [connection error]: The connection errored: 信号灯超时时间已到
Error: SocketException: 信号灯超时时间已到, address = api.openai.com
```

**原因:** 代码仍在使用旧的OpenAI服务而非智谱AI服务。

**解决方案:** ✅ 已修复
- 更新了 `InterpretViewModel.translateText()` 使用智谱AI服务
- 更新了 `RealTimeTranslationService` 使用智谱AI服务
- 所有翻译请求现在都发送到 `https://open.bigmodel.cn`

**验证修复:**
```dart
// 确认使用智谱AI服务
final service = ZhipuTranslationService();
service.setApiKey('your_api_key');
// 请求将发送到: https://open.bigmodel.cn/api/paas/v4
```

---

### ❌ 问题2: API Key未设置或无效

**错误信息:**
```
Exception: API Key未设置
或
Exception: 无效的API Key格式
```

**原因:**
- API Key未配置
- API Key格式错误

**解决方案:**

1. **获取正确的API Key**
   - 访问 https://open.bigmodel.cn/
   - 登录并进入控制台
   - 创建API Key
   - 格式应为: `{id}.{secret}`

2. **配置API Key**
   ```dart
   // 方式1: 直接设置
   viewModel.setZhipuConfig(
     apiKey: '35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf',
   );

   // 方式2: 使用环境变量(推荐)
   // 在 .env 文件中:
   ZHIPU_API_KEY=35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf

   // 在代码中:
   import 'package:aif2f/core/config/app_config.dart';
   viewModel.setZhipuConfig(
     apiKey: AppConfig.zhipuApiKey,
   );
   ```

3. **验证API Key格式**
   ```bash
   # API Key应该包含一个点号
   echo "35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf" | grep "\."
   ```

---

### ❌ 问题3: 401 未授权错误

**错误信息:**
```
DioException: 401 Unauthorized
```

**可能原因:**
1. API Key错误
2. API Key已过期
3. API密钥权限不足
4. Token生成问题

**解决方案:**

1. **检查API Key是否正确**
   ```dart
   // 在开发环境中打印API Key前几位进行验证
   final apiKey = '35bd6c37532642a4ad0e4899b9dddfe0.SHg4UhGjeMHcArnf';
   debugPrint('API Key: ${apiKey.substring(0, 10)}...');
   ```

2. **重新生成API Key**
   - 登录智谱AI控制台
   - 删除旧的API Key
   - 创建新的API Key
   - 更新应用配置

3. **检查API权限**
   - 确认API Key有访问权限
   - 检查账户余额
   - 验证服务状态

---

### ❌ 问题4: 429 请求频率限制

**错误信息:**
```
DioException: 429 Too Many Requests
```

**原因:** 超过API调用频率限制

**解决方案:**

1. **实现请求队列**
   ```dart
   class RequestQueue {
     final Duration delay = Duration(seconds: 1);
     DateTime? _lastRequestTime;

     Future<void> waitIfNeeded() async {
       if (_lastRequestTime != null) {
         final elapsed = DateTime.now().difference(_lastRequestTime!);
         if (elapsed < delay) {
           await Future.delayed(delay - elapsed);
         }
       }
       _lastRequestTime = DateTime.now();
     }
   }
   ```

2. **添加重试机制**
   ```dart
   Future<T> retryWithBackoff<T>(
     Future<T> Function() fn, {
     int maxRetries = 3,
     Duration initialDelay = const Duration(seconds: 1),
   }) async {
     int attempt = 0;
     while (attempt < maxRetries) {
       try {
         return await fn();
       } catch (e) {
         attempt++;
         if (attempt >= maxRetries) rethrow;
         final delay = initialDelay * pow(2, attempt);
         await Future.delayed(delay);
       }
     }
     throw Exception('Max retries exceeded');
   }
   ```

3. **监控API使用量**
   - 在智谱AI控制台查看使用统计
   - 设置使用量告警
   - 优化请求频率

---

### ❌ 问题5: 音频文件处理错误

**错误信息:**
```
Exception: 音频文件不存在: /path/to/audio.wav
或
Exception: 语音识别失败: 400
```

**可能原因:**
1. 音频文件路径错误
2. 音频格式不支持
3. 音频文件损坏
4. 文件大小超限

**解决方案:**

1. **验证音频文件存在**
   ```dart
   final file = File(audioFilePath);
   if (!await file.exists()) {
     throw Exception('音频文件不存在: $audioFilePath');
   }

   // 检查文件大小
   final fileSize = await file.length();
   if (fileSize == 0) {
     throw Exception('音频文件为空');
   }

   // 智谱AI限制文件大小为25MB
   if (fileSize > 25 * 1024 * 1024) {
     throw Exception('音频文件过大(最大25MB)');
   }
   ```

2. **使用推荐的音频配置**
   ```dart
   RecordConfig(
     encoder: AudioEncoder.wav,      // WAV格式
     sampleRate: 16000,              // 16kHz采样率
     bitRate: 128000,                // 128kbps
     numChannels: 1,                 // 单声道
   )
   ```

3. **支持的音频格式**
   - WAV (推荐)
   - MP3
   - M4A
   - FLAC
   - OGG

---

### ❌ 问题6: 翻译结果为空

**错误信息:**
```dart
// 没有错误，但translatedText为空字符串
if (result.translatedText.isEmpty) {
  print('翻译结果为空');
}
```

**可能原因:**
1. API返回了空结果
2. 响应解析错误
3. 语言设置不正确

**解决方案:**

1. **添加详细日志**
   ```dart
   try {
     final result = await service.translateAudio(...);

     debugPrint('识别文本: ${result.recognizedText}');
     debugPrint('翻译文本: ${result.translatedText}');
     debugPrint('源语言: ${result.sourceLanguage}');
     debugPrint('目标语言: ${result.targetLanguage}');

     if (result.translatedText.isEmpty) {
       // 检查识别文本是否为空
       if (result.recognizedText.isEmpty) {
         debugPrint('语音识别失败，请检查音频质量');
       } else {
         debugPrint('翻译失败，API返回空结果');
       }
     }
   } catch (e) {
     debugPrint('详细错误: $e');
   }
   ```

2. **验证语言代码**
   ```dart
   // 确保使用正确的语言代码
   final supportedLanguages = {
     '中文': 'zh',
     '英语': 'en',
     '日语': 'ja',
     '韩语': 'ko',
   };

   final langCode = supportedLanguages[languageName] ?? 'zh';
   ```

3. **使用测试模式验证**
   ```dart
   // 使用测试数据验证流程
   final result = await service.translateAudioMock(
     audioFilePath: audioPath,
     sourceLanguage: 'zh',
     targetLanguage: 'en',
   );

   debugPrint('测试结果: ${result.translatedText}');
   ```

---

### ❌ 问题7: 网络超时

**错误信息:**
```
DioException: TimeoutException after 0:00:30.000000
```

**原因:** 网络连接不稳定或服务器响应慢

**解决方案:**

1. **增加超时时间**
   ```dart
   final dio = Dio();
   dio.options.connectTimeout = Duration(seconds: 30);
   dio.options.receiveTimeout = Duration(seconds: 60);
   dio.options.sendTimeout = Duration(seconds: 30);
   ```

2. **检查网络连接**
   ```dart
   Future<bool> checkConnectivity() async {
     try {
       final response = await dio.get('https://www.baidu.com');
       return response.statusCode == 200;
     } catch (e) {
       return false;
     }
   }

   // 使用前检查网络
   final isConnected = await checkConnectivity();
   if (!isConnected) {
     throw Exception('网络连接不可用');
   }
   ```

3. **添加重试逻辑**
   - 参考问题4的解决方案

---

## 调试技巧

### 1. 启用详细日志

```dart
import 'package:flutter/foundation.dart';

// 在main.dart中
void main() {
  // 启用详细日志
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(MyApp());
}
```

### 2. 使用调试工具

```dart
// 在服务中添加调试日志
class ZhipuTranslationService {
  Future<String> translateText({...}) async {
    try {
      debugPrint('=== 翻译请求 ===');
      debugPrint('文本: $text');
      debugPrint('源语言: $sourceLanguage');
      debugPrint('目标语言: $targetLanguage');
      debugPrint('API URL: $_baseUrl');

      final response = await _dio.post(...);

      debugPrint('=== 响应 ===');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据: ${response.data}');

      return result;
    } catch (e) {
      debugPrint('=== 错误 ===');
      debugPrint('异常: $e');
      rethrow;
    }
  }
}
```

### 3. 测试API连接

```dart
Future<bool> testZhipuConnection() async {
  final service = ZhipuTranslationService();
  service.setApiKey('your_api_key');

  try {
    final result = await service.translateText(
      text: '测试',
      sourceLanguage: 'zh',
      targetLanguage: 'en',
    );

    debugPrint('测试成功: $result');
    return true;
  } catch (e) {
    debugPrint('测试失败: $e');
    return false;
  } finally {
    await service.dispose();
  }
}
```

---

## 性能优化建议

### 1. 缓存翻译结果

```dart
class TranslationCache {
  final Map<String, String> _cache = {};

  String? get(String text, String targetLang) {
    final key = '$text-$targetLang';
    return _cache[key];
  }

  void set(String text, String targetLang, String result) {
    final key = '$text-$targetLang';
    _cache[key] = result;
  }
}
```

### 2. 批量处理

```dart
Future<List<String>> batchTranslate(
  List<String> texts,
  String sourceLanguage,
  String targetLanguage,
) async {
  final results = <String>[];

  for (final text in texts) {
    try {
      final result = await service.translateText(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      results.add(result);
    } catch (e) {
      results.add('翻译失败: $e');
    }
  }

  return results;
}
```

### 3. 并发控制

```dart
import 'dart:async';

class ConcurrencyLimiter {
  final int maxConcurrent;
  int _running = 0;
  final List<Future<dynamic>> _queue = [];

  ConcurrencyLimiter(this.maxConcurrent);

  Future<T> run<T>(Future<T> Function() fn) async {
    while (_running >= maxConcurrent) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    _running++;
    try {
      return await fn();
    } finally {
      _running--;
    }
  }
}
```

---

## 获取帮助

如果以上方案都无法解决问题：

1. **查看详细文档**
   - [集成指南](zhipu_ai_integration.md)
   - [API参考](https://open.bigmodel.cn/dev/api)

2. **检查服务状态**
   - 智谱AI状态页面: https://status.zhipuai.cn/
   - 确认服务是否正常运行

3. **联系支持**
   - 智谱AI技术支持
   - GitHub Issues
   - 开发者社区

4. **提供错误信息**
   - 完整的错误堆栈
   - API Key前几位(用于验证格式)
   - 请求和响应的详细信息
   - 重现步骤

---

**最后更新**: 2025-01-13

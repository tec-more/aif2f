import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';

/// 科大讯飞实时语音识别服务
/// 使用同传翻译 API (simult_interpretation)
class XfyunRealtimeAsrService {
  final String _appId;
  final String _apiKey;
  final String _apiSecret;
  final String _wsUrl;

  WebSocketChannel? _wsChannel;
  bool _isConnected = false;

  // 音频序列号和状态管理
  int _audioSeq = 0;
  bool _hasSentFirstMessage = false;

  // 识别文本缓冲区（用于处理流式识别的中间结果）
  StringBuffer _recognitionBuffer = StringBuffer();

  // 识别结果回调
  // Function(String)? onTextRecognized;
  Function(String, int)? onTextDstRecognized;
  Function(String, int)? onTextSrcRecognized;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  XfyunRealtimeAsrService({
    String? appId,
    String? apiKey,
    String? apiSecret,
    String? wsUrl,
  }) : _appId = appId ?? AppConfig.xFAPPID,
       _apiKey = apiKey ?? AppConfig.xFAPIKey,
       _apiSecret = apiSecret ?? AppConfig.xFAPISecret,
       _wsUrl = wsUrl ?? AppConfig.xFInterpretationUrl {
    debugPrint('科大讯飞ASR服务初始化:');
    debugPrint('  APPID: $_appId');
    debugPrint('  APIKey: ${_apiKey.substring(0, 8)}...');
    debugPrint('  APISecret: ${_apiSecret.substring(0, 8)}...');
    debugPrint('  URL: $_wsUrl');
  }

  /// 生成科大讯飞 API 鉴权参数（按照官方文档）
  Map<String, String> _generateAuthParams() {
    // 1. 从 WebSocket URL 中提取 host 和 path
    final uri = Uri.parse(_wsUrl);
    final host = uri.host;
    final path = uri.path;

    // 2. 生成 RFC1123 格式的 date
    final now = DateTime.now().toUtc();
    final date = HttpDate.format(now);

    // 3. 构建 signature_origin
    // 格式: host: $host\ndate: $date\nGET /path HTTP/1.1
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';

    debugPrint('签名原始字段:\n$signatureOrigin');

    // 4. 使用 hmac-sha256 签名
    final key = utf8.encode(_apiSecret);
    final bytes = utf8.encode(signatureOrigin);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    // 5. base64 编码得到 signature
    final signature = base64.encode(digest.bytes);

    debugPrint('签名结果: $signature');

    // 6. 构建 authorization_origin
    final authorizationOrigin =
        'api_key="$_apiKey", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';

    debugPrint('Authorization 原始: $authorizationOrigin');

    // 7. base64 编码得到 authorization
    final authorization = base64.encode(utf8.encode(authorizationOrigin));

    debugPrint('Authorization: $authorization');

    return {'host': host, 'date': date, 'authorization': authorization};
  }

  /// 连接WebSocket并开始识别
  Future<bool> connect() async {
    try {
      if (_isConnected) {
        debugPrint('科大讯飞ASR: 已经连接');
        return true;
      }

      // 重置状态
      _audioSeq = 0;
      _hasSentFirstMessage = false;
      _recognitionBuffer.clear(); // 清空识别缓冲区

      debugPrint('正在连接科大讯飞ASR: $_wsUrl');
      debugPrint('APPID: $_appId');

      // 生成鉴权参数
      final authParams = _generateAuthParams();

      // 构建带鉴权参数的 WebSocket URL
      // 按照官方文档格式添加 serviceId 参数
      final wsUrlWithAuth =
          '$_wsUrl?'
          'authorization=${authParams['authorization']}'
          '&host=${authParams['host']}'
          '&date=${Uri.encodeComponent(authParams['date']!)}'
          '&serviceId=simult_interpretation';

      debugPrint('WebSocket URL: $wsUrlWithAuth');
      debugPrint('正在建立 WebSocket 连接，最长等待 30 秒...');

      // 创建WebSocket连接
      _wsChannel = IOWebSocketChannel.connect(wsUrlWithAuth);

      // 等待连接真正建立（增加超时时间到30秒）
      await _wsChannel!.ready
          .then((_) {
            _isConnected = true;
            debugPrint('✅ 科大讯飞ASR: WebSocket 连接成功');
            onConnected?.call();
          })
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('❌ 科大讯飞ASR: 连接超时（30秒）');
              debugPrint('可能原因：');
              debugPrint('  1. 无法访问 ws-api.xf-yun.com（网络问题/防火墙）');
              debugPrint('  2. API 密钥配置错误');
              debugPrint('  3. 需要使用 VPN');
              throw Exception('连接超时：30秒内无法建立WebSocket连接');
            },
          );

      debugPrint('开始监听 WebSocket 消息...');

      // 监听消息
      _wsChannel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('❌ 科大讯飞ASR: 消息错误: $error');
          debugPrint('错误详情: $error');
          _isConnected = false;
          onError?.call('消息处理错误: $error');
        },
        onDone: () {
          debugPrint('🔌 科大讯飞ASR: 连接关闭 (onDone触发)');
          debugPrint('可能原因:');
          debugPrint('  1. 服务端主动关闭连接');
          debugPrint('  2. 网络中断');
          debugPrint('  3. 消息格式错误导致服务端拒绝');
          debugPrint('  4. 未发送必要的配置消息');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      debugPrint('科大讯飞ASR: connect() 返回，连接状态: $_isConnected');
      debugPrint('');
      debugPrint('🔍 连接成功，准备发送音频数据');
      debugPrint('  ✓ WebSocket 连接已建立');
      debugPrint('  ✓ 将按照科大讯飞官方格式发送消息');
      debugPrint('  ✓ 首条消息将包含完整配置参数');
      debugPrint('');
      return _isConnected;
    } catch (e) {
      debugPrint('❌ 科大讯飞ASR: 连接失败: $e');
      onError?.call('连接失败: $e');
      _isConnected = false;
      return false;
    }
  }

  /// 发送音频数据
  void sendAudioData(List<int> audioData) {
    if (!_isConnected || _wsChannel == null) {
      debugPrint('科大讯飞ASR: 未连接');
      return;
    }

    // 将音频数据转换为 base64
    final base64Audio = base64Encode(audioData);

    // 确定当前状态（0=第一帧, 1=中间帧, 2=最后一帧）
    final status = _hasSentFirstMessage ? 1 : 0;

    // 构建符合官方格式的消息
    Map<String, dynamic> message;

    if (!_hasSentFirstMessage) {
      // 第一次发送：包含完整的配置参数
      message = {
        'header': {'app_id': _appId, 'status': status},
        'parameter': {
          'ist': {
            'language': 'zh_cn',
            'language_type': 1,
            'domain': 'ist_ed_open',
            'accent': 'mandarin',
          },
          'streamtrans': {'from': 'cn', 'to': 'en'},
          'tts': {
            'vcn': 'x2_catherine',
            'tts_results': {
              'encoding': 'raw',
              'sample_rate': 16000,
              'channels': 1,
              'bit_depth': 16,
            },
          },
        },
        'payload': {
          'data': {
            'audio': base64Audio,
            'encoding': 'raw',
            'sample_rate': 16000,
            'seq': _audioSeq,
            'status': status,
          },
        },
      };
      _hasSentFirstMessage = true;
    } else {
      // 后续发送：只包含必要字段
      message = {
        'header': {'app_id': _appId, 'status': status},
        'payload': {
          'data': {
            'audio': base64Audio,
            'encoding': 'raw',
            'sample_rate': 16000,
            'seq': _audioSeq,
            'status': status,
          },
        },
      };
    }

    final messageJson = jsonEncode(message);

    // 每100条消息打印一次状态
    if (_audioSeq % 100 == 0 || _audioSeq < 5) {
      debugPrint(
        '📤 科大讯飞ASR发送消息 #$_audioSeq (状态: $status, 大小: ${messageJson.length} 字符)',
      );
    }

    _wsChannel!.sink.add(messageJson);
    _audioSeq++;
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);

        // 调试：打印payload中的所有字段
        if (data['payload'] != null) {
          final payload = data['payload'] as Map<String, dynamic>;
          final payloadKeys = payload.keys.join(', ');
          if (payloadKeys.isNotEmpty) {
            debugPrint('📦 Payload包含: $payloadKeys');
          }
        }

        // 处理header中的错误码
        if (data['header'] != null) {
          final header = data['header'] as Map<String, dynamic>;
          final code = header['code'];
          final sid = header['sid'];

          if (sid != null && _audioSeq % 100 == 0) {
            debugPrint('📡 科大讯飞ASR会话: $sid');
          }

          if (code != null && code != 0) {
            final errorMsg = header['message'] ?? '未知错误';
            debugPrint('❌ 科大讯飞ASR: 错误 ($code): $errorMsg');
            onError?.call('识别错误: $errorMsg');
            return;
          }
        }

        // 处理识别结果 (payload.recognition_results)
        if (data['payload'] != null &&
            data['payload']['recognition_results'] != null) {
          final recognitionResults = data['payload']['recognition_results'];
          final textBase64 = recognitionResults['text'];

          if (textBase64 != null && textBase64.isNotEmpty) {
            try {
              // 解码base64文本
              final textBytes = base64Decode(textBase64);
              final textJson = utf8.decode(textBytes);
              final textData = jsonDecode(textJson);

              // 科大讯飞返回的格式：{bg, ed, ls, pgs, rg, sn, sub_end, ws: [{cw: [{w, sc, wc, wb, we, wp}], bg}]}
              // ls: true 表示句子结束（最终结果）
              // pgs: "rpl" 表示替换之前的结果，"apd" 表示追加
              final pgs = textData['rpl']; // "rpl" 或 "apd"

              // 提取识别文本
              if (textData is Map && textData['ws'] != null) {
                final ws = textData['ws'] as List;
                final recognizedText = StringBuffer();

                for (var wordBlock in ws) {
                  if (wordBlock is Map && wordBlock['cw'] != null) {
                    final cw = wordBlock['cw'] as List;
                    if (cw.isNotEmpty && cw[0] is Map) {
                      final firstCandidate = cw[0] as Map;
                      final word = firstCandidate['w'];
                      if (word != null) {
                        recognizedText.write(word);
                      }
                    }
                  }
                }

                final text = recognizedText.toString();

                if (text.isNotEmpty) {
                  // 根据pgs类型更新缓冲区
                  if (pgs == 'rpl') {
                    // 替换模式：清空缓冲区并设置新文本
                    _recognitionBuffer.clear();
                    _recognitionBuffer.write(text);
                  } else {
                    // 追加模式：直接追加
                    _recognitionBuffer.write(text);
                  }
                }
              }
            } catch (e) {
              debugPrint('解码识别文本失败: $e');
            }
          }
        }

        // 处理翻译结果 (payload.streamtrans_results)
        if (data['payload'] != null &&
            data['payload']['streamtrans_results'] != null) {
          debugPrint('🌐 收到翻译结果');
          final transResults = data['payload']['streamtrans_results'];
          final textBase64 = transResults['text'];

          if (textBase64 != null && textBase64.isNotEmpty) {
            try {
              // 解码base64文本
              final textBytes = base64Decode(textBase64);
              final textJson = utf8.decode(textBytes);
              final textData = jsonDecode(textJson);

              debugPrint('翻译结果JSON: $textData');

              // 提取翻译文本
              // textData 可能是 Map（单个翻译）或 List（多个翻译）
              if (textData is Map) {
                // 单个翻译结果
                final src = textData['src'];
                final dst = textData['dst'];
                final isFinal = textData['is_final'] ?? 0;

                if (src != null) {
                  debugPrint('📝 科大讯飞ASR原文（中文）: $src (is_final: $isFinal)');
                  onTextSrcRecognized?.call(src, isFinal); // 原文→ inputOneText
                }
                if (dst != null) {
                  debugPrint('🌏 科大讯飞ASR译文（英文）: $dst (is_final: $isFinal)');
                  onTextDstRecognized?.call(dst, isFinal); // 译文→ translatedOneText
                }
              } else if (textData is List) {
                // 多个翻译结果（数组格式）
                for (var item in textData) {
                  if (item is Map) {
                    final src = item['src'];
                    final dst = item['dst'];
                    final isFinal = item['is_final'] ?? 0;

                    if (src != null) {
                      debugPrint('📝 科大讯飞ASR原文（中文）: $src (is_final: $isFinal)');
                      onTextSrcRecognized?.call(src, isFinal); // 原文→ inputOneText
                    }
                    if (dst != null) {
                      debugPrint('🌏 科大讯飞ASR译文（英文）: $dst (is_final: $isFinal)');
                      onTextDstRecognized?.call(dst, isFinal); // 译文→ translatedOneText
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('解码翻译文本失败: $e');
            }
          }
        } else {
          // 只有识别结果，没有翻译结果
          if (data['payload'] != null &&
              data['payload']['recognition_results'] != null) {
            debugPrint('⚠️ 本次响应只有识别结果，没有翻译结果');
            debugPrint('   翻译结果通常在完整句子结束后才返回');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 科大讯飞ASR: 解析消息失败: $e');
      debugPrint('无法解析的消息内容: $message');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_wsChannel != null) {
      // 发送结束帧（如果已经发送过数据）
      if (_hasSentFirstMessage && _isConnected) {
        _sendEndFrame();
        // 等待一小段时间让结束帧发送出去
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _wsChannel!.sink.close();
      _wsChannel = null;
      _isConnected = false;
      _audioSeq = 0;
      _hasSentFirstMessage = false;
      _recognitionBuffer.clear(); // 清空识别缓冲区
      debugPrint('科大讯飞ASR: 已断开连接');
    }
  }

  /// 发送结束帧
  void _sendEndFrame() {
    if (_wsChannel == null || !_isConnected) return;

    final endFrame = {
      'header': {'app_id': _appId, 'status': 2},
      'payload': {
        'data': {
          'audio': '',
          'encoding': 'raw',
          'sample_rate': 16000,
          'seq': _audioSeq,
          'status': 2,
        },
      },
    };

    final messageJson = jsonEncode(endFrame);
    debugPrint('========== 科大讯飞ASR发送结束帧 ==========');
    debugPrint('状态: 2 (最后一帧/结束)');
    debugPrint('=========================================');

    _wsChannel!.sink.add(messageJson);
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}

/// 科大讯飞ASR识别结果
class XfyunAsrResult {
  final String text;
  final bool isFinal;
  final bool isSuccess;
  final String? errorMessage;

  XfyunAsrResult({
    required this.text,
    this.isFinal = false,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory XfyunAsrResult.failure(String errorMessage) {
    return XfyunAsrResult(
      text: '',
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    final preview = text.length > 50 ? text.substring(0, 50) : text;
    return 'XfyunAsrResult(text: "$preview...", isFinal: $isFinal)';
  }
}

/// 科大讯飞ASR配置类
class XfyunAsrConfig {
  final String appId;
  final String apiKey;
  final String apiSecret;
  final String wsUrl;

  const XfyunAsrConfig({
    required this.appId,
    required this.apiKey,
    required this.apiSecret,
    this.wsUrl = AppConfig.xFInterpretationUrl,
  });

  /// 从环境变量或AppConfig加载配置
  factory XfyunAsrConfig.fromEnv() {
    // 从 AppConfig.xFAPPID 解析

    return XfyunAsrConfig(
      appId: AppConfig.xFAPPID,
      apiKey: AppConfig.xFAPIKey,
      apiSecret: AppConfig.xFAPISecret,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'apiKey': apiKey,
      'apiSecret': apiSecret,
      'wsUrl': wsUrl,
    };
  }

  @override
  String toString() {
    return 'XfyunAsrConfig(appId: $appId, wsUrl: $wsUrl)';
  }
}

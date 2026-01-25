import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:flutter_f2f_sound/flutter_f2f_sound.dart';
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

  // TTS 音频播放器和缓冲队列（一栏）
  final FlutterF2fSound _ttsPlayer1 = FlutterF2fSound();
  final List<Uint8List> _ttsAudioBuffer1 = [];
  final List<String> _ttsFilePaths1 = [];
  bool _isPlayingTts1 = false;
  bool _isTtsEnabled1 = false;  // 一栏 TTS 播放开关

  // TTS 音频播放器和缓冲队列（二栏）
  final FlutterF2fSound _ttsPlayer2 = FlutterF2fSound();
  final List<Uint8List> _ttsAudioBuffer2 = [];
  final List<String> _ttsFilePaths2 = [];
  bool _isPlayingTts2 = false;
  bool _isTtsEnabled2 = false;  // 二栏 TTS 播放开关

  // 当前音频数据类型（1=一栏/系统声音, 2=二栏/录音）
  int _currentAudioType = 1;

  // 识别结果回调
  // Function(String)? onTextRecognized;
  Function(String, int)? onTextDstRecognized;
  Function(String, int)? onTextSrcRecognized;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(Uint8List)? onTtsAudioReceived;
  Function(int, bool)? onTtsStateChanged;  // TTS 状态变化回调 (type, isEnabled)

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
  /// [type] 音频类型：1 = 一栏（系统声音）, 2 = 二栏（录音），默认为 1
  void sendAudioData(List<int> audioData, {int type = 1}) {
    // 更新当前音频类型
    _currentAudioType = type;

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
        }

        // 处理 TTS 音频结果 (payload.tts_results)
        if (data['payload'] != null &&
            data['payload']['tts_results'] != null) {
          debugPrint('🔊 收到 TTS 音频片段');
          final ttsResults = data['payload']['tts_results'];
          final audioBase64 = ttsResults['audio'];

          if (audioBase64 != null && audioBase64.isNotEmpty) {
            try {
              // 解码 base64 音频数据
              final audioBytes = base64Decode(audioBase64);

              debugPrint('🔊 TTS 音频片段大小: ${audioBytes.length} 字节');

              // 触发 TTS 音频回调
              onTtsAudioReceived?.call(Uint8List.fromList(audioBytes));

              // 将音频片段添加到播放队列（使用当前音频类型）
              _addToTtsQueue(audioBytes, type: _currentAudioType);
            } catch (e) {
              debugPrint('解码 TTS 音频失败: $e');
            }
          }
        }

        // 只有识别结果，没有翻译结果
        if (data['payload'] != null &&
            data['payload']['recognition_results'] != null &&
            data['payload']['streamtrans_results'] == null) {
          debugPrint('⚠️ 本次响应只有识别结果，没有翻译结果');
          debugPrint('   翻译结果通常在完整句子结束后才返回');
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

  /// 添加 TTS 音频到播放队列并开始播放
  /// type: 1 = 一栏（系统声音）, 2 = 二栏（录音）
  void _addToTtsQueue(List<int> pcmData, {required int type}) {
    // 根据类型获取对应的变量
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;
    final isPlaying = type == 1 ? _isPlayingTts1 : _isPlayingTts2;

    // 如果 TTS 未启用，只接收音频但不播放
    if (!isEnabled) {
      debugPrint('🔇 TTS$type 已禁用，音频已接收但不播放 (${pcmData.length} 字节)');
      return;
    }

    // 将 PCM 转换为 WAV 格式
    final wavData = pcmToWav(Uint8List.fromList(pcmData), sampleRate: 16000, numChannels: 1);

    // 保存到临时文件
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/tts${type}_${timestamp}.wav');
    tempFile.writeAsBytesSync(wavData);

    debugPrint('🔊 TTS$type 音频已添加到队列: $tempFile (${wavData.length} 字节)');

    // 添加到播放队列
    buffer.add(wavData);
    paths.add(tempFile.path);

    // 如果当前没有播放，开始播放队列
    if (!isPlaying) {
      _playNextTts(type: type);
    }
  }

  /// 播放队列中的下一个 TTS 音频
  /// type: 1 = 一栏（系统声音）, 2 = 二栏（录音）
  void _playNextTts({required int type}) {
    // 根据类型获取对应的变量
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;
    final player = type == 1 ? _ttsPlayer1 : _ttsPlayer2;

    // 如果 TTS 被禁用，清空队列并停止播放
    if (!isEnabled) {
      _clearTtsQueue(type: type);
      if (type == 1) {
        _isPlayingTts1 = false;
      } else {
        _isPlayingTts2 = false;
      }
      return;
    }

    if (buffer.isEmpty) {
      debugPrint('✅ TTS$type 播放队列为空，播放完成');
      if (type == 1) {
        _isPlayingTts1 = false;
      } else {
        _isPlayingTts2 = false;
      }
      return;
    }

    if (type == 1) {
      _isPlayingTts1 = true;
    } else {
      _isPlayingTts2 = true;
    }

    buffer.removeAt(0); // 移除音频数据
    final nextPath = paths.removeAt(0);

    debugPrint('🔊 开始播放 TTS$type 音频 (队列剩余: ${buffer.length})');

    player.play(path: nextPath).then((_) {
      debugPrint('✅ TTS$type 音频片段播放完成');
      // 删除已播放的临时文件
      try {
        File(nextPath).deleteSync();
      } catch (e) {
        debugPrint('⚠️ 删除临时文件失败: $e');
      }
      // 继续播放下一个
      _playNextTts(type: type);
    }).catchError((error) {
      debugPrint('❌ TTS$type 播放失败: $error');
      // 出错也继续播放下一个
      _playNextTts(type: type);
    });
  }

  /// 清空 TTS 播放队列
  /// type: 1 = 一栏（系统声音）, 2 = 二栏（录音）
  void _clearTtsQueue({required int type}) {
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;

    // 删除所有临时文件
    for (final path in paths) {
      try {
        File(path).deleteSync();
      } catch (e) {
        debugPrint('⚠️ 删除临时文件失败: $e');
      }
    }
    // 清空队列
    buffer.clear();
    paths.clear();
    debugPrint('🗑️ TTS$type 播放队列已清空');
  }

  /// 启用 TTS 播放
  /// [type] 类型：1 = 一栏, 2 = 二栏
  /// 从当前时刻开始播放接收到的 TTS 音频
  void enableTts({required int type}) {
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;

    if (!isEnabled) {
      if (type == 1) {
        _isTtsEnabled1 = true;
      } else {
        _isTtsEnabled2 = true;
      }
      debugPrint('✅ TTS$type 播放已启用 - 从当前时刻开始播放 TTS 音频');
      onTtsStateChanged?.call(type, true);
    }
  }

  /// 禁用 TTS 播放
  /// [type] 类型：1 = 一栏, 2 = 二栏
  /// 停止播放当前和后续的 TTS 音频
  void disableTts({required int type}) {
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final player = type == 1 ? _ttsPlayer1 : _ttsPlayer2;
    final isPlaying = type == 1 ? _isPlayingTts1 : _isPlayingTts2;

    if (isEnabled) {
      if (type == 1) {
        _isTtsEnabled1 = false;
      } else {
        _isTtsEnabled2 = false;
      }
      debugPrint('⏸️ TTS$type 播放已禁用 - 停止播放当前和后续 TTS 音频');
      onTtsStateChanged?.call(type, false);

      // 停止当前播放
      player.stop();
      if (type == 1) {
        _isPlayingTts1 = false;
      } else {
        _isPlayingTts2 = false;
      }

      // 清空播放队列
      _clearTtsQueue(type: type);
    }
  }

  /// 获取 TTS 播放状态
  /// [type] 类型：1 = 一栏, 2 = 二栏
  bool isTtsEnabled({required int type}) {
    return type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
  }

  /// 切换 TTS 播放状态
  /// [type] 类型：1 = 一栏, 2 = 二栏
  void toggleTts({required int type}) {
    if (isTtsEnabled(type: type)) {
      disableTts(type: type);
    } else {
      enableTts(type: type);
    }
  }

  /// 将 PCM 音频数据转换为 WAV 格式
  /// 参数:
  /// - pcmData: PCM 音频数据 (16-bit, 单声道)
  /// - sampleRate: 采样率 (默认 16000Hz)
  /// - numChannels: 声道数 (默认 1 = 单声道)
  static Uint8List pcmToWav(Uint8List pcmData, {int sampleRate = 16000, int numChannels = 1}) {
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    // 创建 WAV 文件字节缓冲区
    final BytesBuilder builder = BytesBuilder();

    // RIFF 头
    builder.add(Uint8List.fromList([0x52, 0x49, 0x46, 0x46])); // "RIFF"
    builder.add(_uint32ToLittleEndian(fileSize)); // 文件大小 - 8
    builder.add(Uint8List.fromList([0x57, 0x41, 0x56, 0x45])); // "WAVE"

    // fmt 子块
    builder.add(Uint8List.fromList([0x66, 0x6D, 0x74, 0x20])); // "fmt "
    builder.add(_uint32ToLittleEndian(16)); // fmt 块大小
    builder.add(_uint16ToLittleEndian(1)); // 音频格式 (1 = PCM)
    builder.add(_uint16ToLittleEndian(numChannels)); // 声道数
    builder.add(_uint32ToLittleEndian(sampleRate)); // 采样率
    builder.add(_uint32ToLittleEndian(byteRate)); // 字节率
    builder.add(_uint16ToLittleEndian(blockAlign)); // 块对齐
    builder.add(_uint16ToLittleEndian(bitsPerSample)); // 位深

    // data 子块
    builder.add(Uint8List.fromList([0x64, 0x61, 0x74, 0x61])); // "data"
    builder.add(_uint32ToLittleEndian(dataSize)); // 数据大小

    // PCM 数据
    builder.add(pcmData);

    return builder.takeBytes();
  }

  /// 将 32 位无符号整数转换为小端字节序
  static Uint8List _uint32ToLittleEndian(int value) {
    return Uint8List(4)
      ..buffer.asByteData().setUint32(0, value, Endian.little);
  }

  /// 将 16 位无符号整数转换为小端字节序
  static Uint8List _uint16ToLittleEndian(int value) {
    return Uint8List(2)
      ..buffer.asByteData().setUint16(0, value, Endian.little);
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_f2f_sound/flutter_f2f_sound.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';

// 条件日志函数 - 只在调试模式下打印
void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// 火山引擎实时语音识别服务
/// 使用实时语音翻译 API
class VolcanoRealtimeAsrService {
  final String _appId;
  final String _accessKey;
  final String _uri;
  final String _wsUrl;

  WebSocketChannel? _wsChannel;
  bool _isConnected = false;

  // 音频序列号和状态管理
  int _audioSeq = 0;
  int _audioSeqType1 = 0;  // 一栏音频序列号（系统声音）
  int _audioSeqType2 = 0;  // 二栏音频序列号（录音）
  bool _hasSentFirstMessageType1 = false;
  bool _hasSentFirstMessageType2 = false;
  bool _hasSentFirstMessage = false;

  // 序列号到类型的映射（用于路由TTS响应）
  final Map<int, int> _seqToTypeMap = {};

  // 跟踪每种类型最后发送音频的时间戳（用于路由TTS响应）
  DateTime? _lastSendTimeType1;
  DateTime? _lastSendTimeType2;

  // TTS 音频播放器和缓冲队列（一栏）
  final FlutterF2fSound _ttsPlayer1 = FlutterF2fSound();
  final List<Uint8List> _ttsAudioBuffer1 = [];
  final List<String> _ttsFilePaths1 = [];
  bool _isPlayingTts1 = false;
  bool _isTtsEnabled1 = false;
  bool _isFlushing1 = false;

  // TTS 音频播放器和缓冲队列（二栏）
  final FlutterF2fSound _ttsPlayer2 = FlutterF2fSound();
  final List<Uint8List> _ttsAudioBuffer2 = [];
  final List<String> _ttsFilePaths2 = [];
  bool _isPlayingTts2 = false;
  bool _isTtsEnabled2 = false;
  bool _isFlushing2 = false;

  // 识别结果回调
  Function(String, int)? onTextDstRecognized;
  Function(String, int)? onTextSrcRecognized;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(Uint8List)? onTtsAudioReceived;
  Function(int, bool)? onTtsStateChanged;

  VolcanoRealtimeAsrService({
    required String appId,
    required String accessKey,
    required String uri,
    String? wsUrl,
  }) : _appId = appId,
       _accessKey = accessKey,
       _uri = uri,
       _wsUrl = wsUrl ?? 'wss://openspeech.bytedance.com/api/v2/vop?part=&part=rtc.orc.v1' {
    _log('火山引擎ASR服务初始化:');
    _log('  APPID: $_appId');
    _log('  AccessKey: ${_accessKey.substring(0, 8)}...');
    _log('  URI: $_uri');
    _log('  URL: $_wsUrl');
  }

  /// 生成火山引擎 API鉴权参数
  Map<String, String> _generateAuthParams() {
    final now = DateTime.now().toUtc();
    final date = HttpDate.format(now);
    final signatureOrigin = 'host: $_uri\ndate: $date\nGET /$_uri HTTP/1.1';

    // 使用 HMAC-SHA256 生成签名
    final key = utf8.encode(_accessKey);
    final bytes = utf8.encode(signatureOrigin);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final signature = base64.encode(digest.bytes);

    return {
      'host': _uri,
      'date': date,
      'authorization': 'Bearer $_accessKey',
      'signature': signature,
    };
  }

  /// 连接WebSocket并开始识别
  Future<bool> connect() async {
    try {
      if (_isConnected) {
        _log('火山引擎ASR: 已经连接');
        return true;
      }

      // 重置状态
      _audioSeq = 0;
      _hasSentFirstMessage = false;

      _log('正在连接火山引擎ASR: $_wsUrl');
      _log('APPID: $_appId');

      // 生成鉴权参数
      final authParams = _generateAuthParams();

      // 构建带鉴权参数的 WebSocket URL
      final wsUrlWithAuth = '$_wsUrl?'
          'authorization=${Uri.encodeComponent(authParams['authorization']!)}'
          '&host=${Uri.encodeComponent(authParams['host']!)}'
          '&date=${Uri.encodeComponent(authParams['date']!)}'
          '&signature=${Uri.encodeComponent(authParams['signature']!)}';

      _log('WebSocket URL: $wsUrlWithAuth');
      _log('正在建立 WebSocket 连接...');

      // 创建WebSocket连接
      _wsChannel = IOWebSocketChannel.connect(wsUrlWithAuth);

      // 等待连接建立
      await _wsChannel!.ready
          .then((_) {
            _isConnected = true;
            _log('✅ 火山引擎ASR: WebSocket 连接成功');
            onConnected?.call();
          })
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              _log('❌ 火山引擎ASR: 连接超时（30秒）');
              throw Exception('连接超时：30秒内无法建立WebSocket连接');
            },
          );

      _log('开始监听 WebSocket 消息...');

      // 监听消息
      _wsChannel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _log('❌ 火山引擎ASR: 消息错误: $error');
          _isConnected = false;
          onError?.call('消息处理错误: $error');
        },
        onDone: () {
          _log('🔌 火山引擎ASR: 连接关闭 (onDone触发)');
          _log('可能原因:');
          _log('  1. 服务端主动关闭连接');
          _log('  2. 网络中断');
          _log('  3. 消息格式错误导致服务端拒绝');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      _log('🔍 连接成功，准备发送音频数据');
      return _isConnected;
    } catch (e) {
      _log('❌ 火山引擎ASR: 连接失败: $e');
      onError?.call('连接失败: $e');
      _isConnected = false;
      return false;
    }
  }

  /// 发送音频数据
  void sendAudioData(List<int> audioData, {int type = 1}) {
    if (!_isConnected || _wsChannel == null) {
      _log('火山引擎ASR: 未连接');
      return;
    }

    // 将音频数据转换为 base64
    final base64Audio = base64Encode(audioData);

    // 使用类型特定的序列号和状态
    final seq = type == 1 ? _audioSeqType1 : _audioSeqType2;
    final hasSentFirst = type == 1 ? _hasSentFirstMessageType1 : _hasSentFirstMessageType2;
    final status = hasSentFirst ? 1 : 0;

    // 记录序列号到类型的映射
    _seqToTypeMap[seq] = type;

    // 构建符合火山引擎格式的消息
    Map<String, dynamic> message;

    if (!hasSentFirst) {
      // 第一次发送：包含完整的配置参数
      message = {
        'header': {
          'message_id': _generateMessageId(),
          'task_id': _generateTaskId(),
          'status': status,
          'algorithm': {
            'language': 'zh',  // 中文
            'format': 'raw',
            'sample_rate': 16000,
            'bits': 16,
            'channel': 1,
          },
        },
        'payload': {
          'audio_data': base64Audio,
          'seq': seq,
          'status': status,
        },
      };
      if (type == 1) {
        _hasSentFirstMessageType1 = true;
      } else {
        _hasSentFirstMessageType2 = true;
      }
      _hasSentFirstMessage = true;
    } else {
      // 后续发送：只包含必要字段
      message = {
        'header': {
          'message_id': _generateMessageId(),
          'task_id': _generateTaskId(),
          'status': status,
        },
        'payload': {
          'audio_data': base64Audio,
          'seq': seq,
          'status': status,
        },
      };
    }

    final messageJson = jsonEncode(message);

    // 每100条消息打印一次状态
    if (seq % 100 == 0 || seq < 5) {
      _log(
        '📤 火山引擎ASR发送消息 [type=$type] #$seq (状态: $status, 大小: ${messageJson.length} 字符)',
      );
    }

    // 记录发送时间戳
    final now = DateTime.now();
    if (type == 1) {
      _lastSendTimeType1 = now;
    } else {
      _lastSendTimeType2 = now;
    }

    _wsChannel!.sink.add(messageJson);

    // 增加类型特定的序列号
    if (type == 1) {
      _audioSeqType1++;
    } else {
      _audioSeqType2++;
    }

    // 同时更新全局序列号
    _audioSeq++;
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);

        // 处理header
        if (data['header'] != null) {
          final header = data['header'] as Map<String, dynamic>;
          final code = header['code'];
          final sid = header['sid'];
          final errorMsg = header['message'];

          if (code != null && code != 0 && errorMsg != null) {
            _log('❌ 火山引擎ASR: 错误 ($code): $errorMsg');
            onError?.call('识别错误: $errorMsg');
            return;
          }
        }

        // 处理识别结果 (payload.result)
        if (data['payload'] != null &&
            data['payload']['result'] != null) {
          final result = data['payload']['result'];
          final textBase64 = result['text'];
          final isFinal = result['is_final'] ?? 0;
          final audioType = result['audio_type'] ?? 1;

          if (textBase64 != null && textBase64.isNotEmpty) {
            try {
              // 解码base64文本
              final textBytes = base64Decode(textBase64);
              final text = utf8.decode(textBytes);

              if (text.isNotEmpty) {
                _log('📝 火山引擎ASR识别结果: "$text" (is_final: $isFinal, type: $audioType)');

                // 根据audioType分发到不同的回调
                if (audioType == 1) {
                  onTextSrcRecognized?.call(text, isFinal);
                } else if (audioType == 2) {
                  onTextDstRecognized?.call(text, isFinal);
                } else {
                  // 默认行为
                  onTextSrcRecognized?.call(text, isFinal);
                }
              }
            } catch (e) {
              _log('解码识别文本失败: $e');
            }
          }
        }

        // 处理翻译结果 (payload.translation_result)
        if (data['payload'] != null &&
            data['payload']['translation_result'] != null) {
          _log('🌐 收到翻译结果');
          final transResult = data['payload']['translation_result'];
          final textBase64 = transResult['text'];
          final isFinal = transResult['is_final'] ?? 0;

          if (textBase64 != null && textBase64.isNotEmpty) {
            try {
              // 解码base64文本
              final textBytes = base64Decode(textBase64);
              final text = utf8.decode(textBytes);

              if (text.isNotEmpty) {
                _log('🌏 火山引擎ASR译文: "$text" (is_final: $isFinal)');
                onTextDstRecognized?.call(text, isFinal);
              }
            } catch (e) {
              _log('解码翻译文本失败: $e');
            }
          }
        }

        // 处理 TTS 音频结果 (payload.tts_result)
        if (data['payload'] != null &&
            data['payload']['tts_result'] != null) {
          _log('🔊 收到 TTS 音频片段');
          final ttsResult = data['payload']['tts_result'];
          final audioBase64 = ttsResult['audio'];

          if (audioBase64 != null && audioBase64.isNotEmpty) {
            try {
              // 解码 base64 音频数据
              final audioBytes = base64Decode(audioBase64);

              _log('🔊 TTS 音频片段大小: ${audioBytes.length} 字节');

              // 触发 TTS 音频回调
              onTtsAudioReceived?.call(Uint8List.fromList(audioBytes));

              // 将音频片段添加到播放队列
              _addToTtsQueue(audioBytes, type: 1);
            } catch (e) {
              _log('解码 TTS 音频失败: $e');
            }
          }
        }
      }
    } catch (e) {
      _log('❌ 火山引擎ASR: 解析消息失败: $e');
      _log('无法解析的消息内容: $message');
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
      _audioSeqType1 = 0;
      _audioSeqType2 = 0;
      _hasSentFirstMessage = false;
      _hasSentFirstMessageType1 = false;
      _hasSentFirstMessageType2 = false;
      _lastSendTimeType1 = null;
      _lastSendTimeType2 = null;
      _seqToTypeMap.clear();
      _log('火山引擎ASR: 已断开连接');
    }
  }

  /// 发送结束帧
  void _sendEndFrame() {
    if (_wsChannel == null || !_isConnected) return;

    final endFrame = {
      'header': {
        'message_id': _generateMessageId(),
        'task_id': _generateTaskId(),
        'status': 2, // 结束状态
      },
      'payload': {
        'audio_data': '',
        'seq': _audioSeq,
        'status': 2,
      },
    };

    final messageJson = jsonEncode(endFrame);
    _log('========== 火山引擎ASR发送结束帧 ==========');
    _log('状态: 2 (最后一帧/结束)');
    _log('=========================================');

    _wsChannel!.sink.add(messageJson);
  }

  /// 添加 TTS 音频到播放队列并开始播放
  void _addToTtsQueue(List<int> pcmData, {required int type}) {
    // 根据类型获取对应的变量
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;

    // 如果 TTS 未启用，只接收音频但不播放
    if (!isEnabled) {
      _log('🔇 TTS$type 已禁用，音频已接收但不播放 (${pcmData.length} 字节)');
      return;
    }

    // 直接添加 PCM 数据到缓冲区
    buffer.add(Uint8List.fromList(pcmData));

    // 计算缓冲区总大小
    int bufferSize = 0;
    for (final data in buffer) {
      bufferSize += data.length;
    }

    _log('🔊 TTS$type PCM 已添加: ${pcmData.length} 字节, 缓冲区: ${buffer.length} 片段, $bufferSize 字节');

    // 当缓冲区达到一定大小（约 2.5 秒的音频 = 80000 字节）或超过 20 个片段时，立即播放
    if (bufferSize >= 80000 || buffer.length >= 20) {
      _log('⚡ 缓冲区已满 ($bufferSize 字节)，立即播放');
      _flushTtsBuffer(type: type);
    } else {
      // 否则设置定时器，500ms 后播放
      _scheduleTtsPlayback(type: type);
    }
  }

  // 定时器映射
  final Map<int, Timer?> _ttsTimers = {};

  /// 延迟播放 TTS，以累积更多音频数据
  void _scheduleTtsPlayback({required int type}) {
    // 取消之前的定时器
    _ttsTimers[type]?.cancel();

    // 延迟500ms，让更多音频数据积累
    _ttsTimers[type] = Timer(const Duration(milliseconds: 500), () {
      _flushTtsBuffer(type: type);
    });
  }

  /// 将缓冲区的 PCM 数据转换为 WAV 并播放
  void _flushTtsBuffer({required int type}) {
    final isFlushing = type == 1 ? _isFlushing1 : _isFlushing2;
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;

    // 取消定时器
    _ttsTimers[type]?.cancel();
    _ttsTimers[type] = null;

    if (!isEnabled || buffer.isEmpty || isFlushing) {
      return;
    }

    // 设置刷新标志
    if (type == 1) {
      _isFlushing1 = true;
    } else {
      _isFlushing2 = true;
    }

    _log('🔧 准备处理 TTS$type 音频: ${buffer.length} 个片段');

    // 使用 Future.microtask 在下一个微任务中处理，避免阻塞主线程
    Future.microtask(() async {
      try {
        // 计算总大小
        int totalSize = 0;
        for (final data in buffer) {
          totalSize += data.length;
        }

        _log('🔧 合并 TTS$type 音频: ${buffer.length} 个片段, $totalSize 字节');

        // 合并所有 PCM 数据（异步）
        final mergedPcm = Uint8List(totalSize);
        int offset = 0;
        for (final data in buffer) {
          mergedPcm.setRange(offset, offset + data.length, data);
          offset += data.length;
          // 每合并一个片段，让出控制权
          if (offset % 10000 == 0) {
            await Future.delayed(const Duration(microseconds: 0));
          }
        }

        // 清空缓冲区
        buffer.clear();

        // 转换为 WAV 格式
        final wavData = pcmToWav(mergedPcm, sampleRate: 16000, numChannels: 1);

        // 保存到临时文件
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempDir = Directory('temp');
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        final tempFile = File('${tempDir.path}/volcano_tts${type}_$timestamp.wav');

        await tempFile.writeAsBytes(wavData);
        paths.add(tempFile.path);

        _log('✅ TTS$type 音频已生成: ${tempFile.path} (${wavData.length} 字节)');

        // 清除刷新标志
        if (type == 1) {
          _isFlushing1 = false;
        } else {
          _isFlushing2 = false;
        }

        // 开始播放
        _playNextTts(type: type);
      } catch (error) {
        _log('❌ 处理 TTS$type 音频失败: $error');
        // 清除刷新标志
        if (type == 1) {
          _isFlushing1 = false;
        } else {
          _isFlushing2 = false;
        }
      }
    });
  }

  /// 播放队列中的下一个 TTS 音频
  void _playNextTts({required int type}) {
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;
    final player = type == 1 ? _ttsPlayer1 : _ttsPlayer2;

    _log('🎵 _playNextTts 被调用: type=$type, isEnabled=$isEnabled, 待播放文件数=${paths.length}');

    // 如果 TTS 被禁用，清空队列并停止播放
    if (!isEnabled) {
      _log('🚫 TTS$type 已禁用，清空队列');
      _clearTtsQueue(type: type);
      if (type == 1) {
        _isPlayingTts1 = false;
      } else {
        _isPlayingTts2 = false;
      }
      return;
    }

    if (paths.isEmpty) {
      _log('✅ TTS$type 播放队列为空，播放完成');
      if (type == 1) {
        _isPlayingTts1 = false;
      } else {
        _isPlayingTts2 = false;
      }
      // 检查是否还有数据在缓冲区待处理
      if (buffer.isNotEmpty) {
        _log('⚠️ 缓冲区还有数据，刷新并播放');
        _flushTtsBuffer(type: type);
      }
      return;
    }

    if (type == 1) {
      _isPlayingTts1 = true;
    } else {
      _isPlayingTts2 = true;
    }

    final nextPath = paths.removeAt(0);

    _log('🔊 开始播放 TTS$type 音频: $nextPath (剩余: ${paths.length} 个文件)');

    // 检查文件是否存在
    if (!File(nextPath).existsSync()) {
      _log('❌ TTS$type 文件不存在: $nextPath');
      _playNextTts(type: type);
      return;
    }

    // 使用 flutter_f2f_sound 播放器播放
    player.play(path: nextPath, volume: 1.0).then((_) {
      _log('📤 TTS$type 播放命令已发送');
    }).catchError((error) {
      _log('❌ TTS$type 播放失败: $error');
    });

    // 计算音频时长并等待播放完成
    final file = File(nextPath);
    final fileSize = file.lengthSync();
    final audioDataSize = fileSize - 44; // 减去 WAV 头部
    final durationMs = (audioDataSize / 32000 * 1000).ceil();

    _log('⏱️ TTS$type 音频时长约: ${durationMs}ms, 文件大小: $fileSize 字节');

    // 等待播放完成
    Future.delayed(Duration(milliseconds: durationMs + 100), () {
      _log('✅ TTS$type 批量音频播放完成');

      // 删除已播放的临时文件
      try {
        File(nextPath).deleteSync();
        _log('🗑️ 已删除临时文件: $nextPath');
      } catch (e) {
        _log('⚠️ 删除临时文件失败: $e');
      }

      // 继续播放下一个
      _playNextTts(type: type);
    });
  }

  /// 清空 TTS 播放队列
  void _clearTtsQueue({required int type}) {
    final buffer = type == 1 ? _ttsAudioBuffer1 : _ttsAudioBuffer2;
    final paths = type == 1 ? _ttsFilePaths1 : _ttsFilePaths2;

    // 取消定时器
    _ttsTimers[type]?.cancel();
    _ttsTimers[type] = null;

    // 删除所有临时文件
    for (final path in paths) {
      try {
        File(path).deleteSync();
      } catch (e) {
        _log('⚠️ 删除临时文件失败: $e');
      }
    }
    // 清空队列
    buffer.clear();
    paths.clear();
    _log('🗑️ TTS$type 播放队列已清空');
  }

  /// 启用 TTS 播放
  void enableTts({required int type}) {
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;

    _log('🎛️ enableTts 被调用: type=$type, 当前状态=$isEnabled');

    if (!isEnabled) {
      if (type == 1) {
        _isTtsEnabled1 = true;
      } else {
        _isTtsEnabled2 = true;
      }
      _log('✅ TTS$type 播放已启用');
      onTtsStateChanged?.call(type, true);
    } else {
      _log('⚠️ TTS$type 已经是启用状态，无需重复启用');
    }
  }

  /// 禁用 TTS 播放
  void disableTts({required int type}) {
    final isEnabled = type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;

    if (isEnabled) {
      if (type == 1) {
        _isTtsEnabled1 = false;
      } else {
        _isTtsEnabled2 = false;
      }
      _log('⏸️ TTS$type 播放已禁用');
      onTtsStateChanged?.call(type, false);

      // 清空播放队列
      _clearTtsQueue(type: type);
    }
  }

  /// 获取 TTS 播放状态
  bool isTtsEnabled({required int type}) {
    return type == 1 ? _isTtsEnabled1 : _isTtsEnabled2;
  }

  /// 切换 TTS 播放状态
  void toggleTts({required int type}) {
    if (isTtsEnabled(type: type)) {
      disableTts(type: type);
    } else {
      enableTts(type: type);
    }
  }

  /// 将 PCM 音频数据转换为 WAV 格式
  static Uint8List pcmToWav(Uint8List pcmData, {int sampleRate = 16000, int numChannels = 1}) {
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final BytesBuilder builder = BytesBuilder();

    // RIFF header
    builder.add(Uint8List.fromList([0x52, 0x49, 0x46, 0x58])); // "RIFF"
    builder.add(_uint32ToLittleEndian(fileSize));
    builder.add(Uint8List.fromList([0x57, 0x41, 0x56, 0x45])); // "WAVE"

    // fmt subchunk
    builder.add(Uint8List.fromList([0x66, 0x6D, 0x74, 0x20])); // "fmt "
    builder.add(_uint32ToLittleEndian(16)); // fmt chunk size
    builder.add(_uint16ToLittleEndian(1)); // PCM format
    builder.add(_uint16ToLittleEndian(numChannels));
    builder.add(_uint32ToLittleEndian(sampleRate));
    builder.add(_uint32ToLittleEndian(byteRate));
    builder.add(_uint16ToLittleEndian(blockAlign));
    builder.add(_uint16ToLittleEndian(bitsPerSample));

    // data subchunk
    builder.add(Uint8List.fromList([0x64, 0x61, 0x74, 0x61])); // "data"
    builder.add(_uint32ToLittleEndian(dataSize));
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

  /// 生成消息ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_audioSeq}';
  }

  /// 生成任务ID
  String _generateTaskId() {
    return 'task-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}

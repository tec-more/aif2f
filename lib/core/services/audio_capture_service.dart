import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// 音频捕获服务
class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  StreamController<List<int>>? _audioStreamController;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  Stream<List<int>>? get audioStream => _audioStreamController?.stream;

  /// 请求麦克风权限
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        debugPrint('麦克风权限已授予');
        return true;
      } else if (status.isDenied) {
        debugPrint('麦克风权限被拒绝');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('麦克风权限被永久拒绝，需要用户在设置中手动开启');
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('请求麦克风权限失败: $e');
      return false;
    }
  }

  /// 开始录音
  Future<bool> startRecording() async {
    if (_isRecording) {
      debugPrint('已经在录音中');
      return false;
    }

    try {
      // 检查权限
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('没有录音权限，正在请求权限...');
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('麦克风权限未授予');
          return false;
        }
      }

      // 生成临时文件路径 - 使用 WAV 格式以获得更好的兼容性
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/recording_$timestamp.wav';

      debugPrint('录音文件路径: $_currentRecordingPath');

      // 开始录音 - 使用 WAV 格式（OpenAI Whisper 更好支持）
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // Whisper 推荐的采样率
          bitRate: 128000,
          numChannels: 1, // 单声道
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _isPaused = false;
      debugPrint('开始录音: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('开始录音失败: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  /// 停止录音
  Future<String?> stopRecording() async {
    if (!_isRecording && !_isPaused) {
      debugPrint('没有正在进行的录音');
      return null;
    }

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _isPaused = false;

      // 验证文件是否存在
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('停止录音: $path, 文件大小: $fileSize bytes');

          // 如果文件太小，可能是录音失败
          if (fileSize < 1000) {
            debugPrint('警告: 录音文件过小，可能录音失败');
          }
        } else {
          debugPrint('警告: 录音文件不存在');
          return null;
        }
      }

      return path;
    } catch (e) {
      debugPrint('停止录音失败: $e');
      _isRecording = false;
      _isPaused = false;
      return null;
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    if (_isRecording && !_isPaused) {
      try {
        await _recorder.pause();
        _isPaused = true;
        debugPrint('暂停录音');
      } catch (e) {
        debugPrint('暂停录音失败: $e');
      }
    }
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    if (_isRecording && _isPaused) {
      try {
        await _recorder.resume();
        _isPaused = false;
        debugPrint('恢复录音');
      } catch (e) {
        debugPrint('恢复录音失败: $e');
      }
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    if (_isRecording || _isPaused) {
      try {
        await _recorder.stop();
        _isRecording = false;
        _isPaused = false;

        // 删除临时文件
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('已删除临时录音文件: $_currentRecordingPath');
          }
        }
        _currentRecordingPath = null;
        debugPrint('取消录音');
      } catch (e) {
        debugPrint('取消录音失败: $e');
      }
    }
  }

  /// 清理临时文件
  Future<void> cleanup() async {
    try {
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('清理临时文件: $_currentRecordingPath');
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      debugPrint('清理临时文件失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      // 停止录音
      if (_isRecording || _isPaused) {
        await cancelRecording();
      }

      // 关闭流控制器
      await _audioStreamController?.close();

      // 释放录音器资源
      await _recorder.dispose();

      debugPrint('音频捕获服务已释放');
    } catch (e) {
      debugPrint('释放音频捕获服务失败: $e');
    }
  }
}

import 'package:package_info_plus/package_info_plus.dart';

/// 应用信息工具类
class AppInfoUtil {
  static String _version = '未知版本';
  static String _fullVersion = '未知版本';
  static bool _initialized = false;

  /// 初始化应用信息
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      _fullVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      _initialized = true;
      print('📱 应用版本：$_version');
    } catch (e) {
      print('❌ 读取版本号失败：$e');
      _version = '1.0.0'; // 默认版本
      _fullVersion = '1.0.0+1'; // 默认完整版本
    }
  }

  /// 获取版本号
  static Future<String> getVersion() async {
    if (!_initialized) {
      await init();
    }
    return _version;
  }

  /// 获取完整的版本字符串（包含构建号）
  static Future<String> getFullVersion() async {
    if (!_initialized) {
      await init();
    }
    return _fullVersion;
  }
}

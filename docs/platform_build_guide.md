# 多平台构建指南

## 问题说明

`flutter_sound` 插件**不支持 Windows 平台**，但支持 Android 和 iOS。这导致在 Windows 上构建时会出现 CMake 错误：

```
CMake Error: No target "flutter_sound_plugin"
```

## 解决方案

我们采用了**平台特定依赖管理**的方法：

### Windows 构建

**当前配置（pubspec.yaml）：**
```yaml
dependencies:
  # flutter_sound 已注释，以支持 Windows 构建
  # flutter_sound: ^9.30.0

  # path_provider 和 permission_handler 也已注释
  # path_provider: ^2.1.2
  # permission_handler: ^12.0.1
```

**构建命令：**
```bash
flutter build windows
```

**功能限制：**
- ✅ 文本翻译功能正常
- ❌ 录音功能不可用（显示提示消息）

### 移动平台构建（Android/iOS）

**步骤：**

1. **备份当前的 pubspec.yaml：**
   ```bash
   cp pubspec.yaml pubspec.yaml.windows
   ```

2. **恢复移动平台依赖：**
   ```bash
   cp pubspec.yaml.mobile pubspec.yaml
   ```

   或者手动编辑 `pubspec.yaml`，取消以下行的注释：
   ```yaml
   dependencies:
     flutter_sound: ^9.30.0
     path_provider: ^2.1.2
     permission_handler: ^12.0.1
   ```

3. **获取依赖并构建：**
   ```bash
   # 清理旧的构建
   flutter clean

   # 获取依赖（包含 flutter_sound）
   flutter pub get

   # 构建 Android APK
   flutter build apk

   # 或构建 iOS
   flutter build ios
   ```

**功能完整：**
- ✅ 文本翻译功能
- ✅ 录音翻译功能

## 自动切换脚本

为了方便切换，我们提供了以下脚本：

### 切换到 Windows 构建

创建 `switch_to_windows.sh`（或 `.bat`）：
```bash
#!/bin/bash
# 注释掉移动平台专用依赖
sed -i 's/^  flutter_sound:/  # flutter_sound:/' pubspec.yaml
sed -i 's/^  path_provider:/  # path_provider:/' pubspec.yaml
sed -i 's/^  permission_handler:/  # permission_handler:/' pubspec.yaml
flutter clean && flutter pub get
```

### 切换到移动平台构建

创建 `switch_to_mobile.sh`（或 `.bat`）：
```bash
#!/bin/bash
# 取消注释移动平台专用依赖
sed -i 's/^  # flutter_sound:/  flutter_sound:/' pubspec.yaml
sed -i 's/^  # path_provider:/  path_provider:/' pubspec.yaml
sed -i 's/^  # permission_handler:/  permission_handler:/' pubspec.yaml
flutter clean && flutter pub get
```

## 代码实现

### TranslationService

`lib/core/services/translation_service_io.dart` 文件包含了跨平台的实现：

```dart
class TranslationService {
  bool get _supportsRecording => Platform.isAndroid || Platform.isIOS;

  Future<bool> startStreaming() async {
    if (!_supportsRecording) {
      debugPrint('录音功能仅在移动平台（iOS/Android）上支持');
      _errorController.add('录音功能仅在移动平台（iOS/Android）上支持');
      return false;
    }

    // Windows 构建：这些依赖不可用
    // 移动构建：完整的录音功能
  }
}
```

## 文件结构

```
lib/core/services/
├── translation_service.dart       # 主入口（导出 IO 实现）
├── translation_service_io.dart    # IO 平台实现（当前使用）
└── translation_service_stub.dart  # 存根实现（未使用）

pubspec.yaml                        # Windows 构建（默认）
pubspec.yaml.mobile                 # 移动平台构建备份
```

## 验证构建

### 验证 Windows 构建
```bash
flutter build windows
# 应该看到：√ Built build\windows\x64\runner\Release\aif2f.exe
```

### 验证 Android 构建
```bash
# 先切换到移动配置
cp pubspec.yaml.mobile pubspec.yaml
flutter clean && flutter pub get
flutter build apk
# 应该看到：√ Built build\app\outputs\flutter-apk\app-release.apk
```

## 注意事项

1. **不要提交两个版本的 pubspec.yaml** 到 Git - 只需保留 `pubspec.yaml.mobile` 作为参考

2. **CI/CD 配置**：在构建脚本中根据目标平台动态修改 `pubspec.yaml`

3. **录音功能**：在 Windows 上，UI 可以隐藏录音按钮，或显示"不可用"提示

## 未来改进

考虑使用以下替代方案：
- 使用支持所有平台的音频插件（如 `audio_players`）
- 为 Windows 实现一个简单的录音功能
- 使用 Flutter 的条件编译功能（当官方支持时）

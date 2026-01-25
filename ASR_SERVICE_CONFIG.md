# ASR 服务配置说明

## 概述

应用支持多个ASR（自动语音识别）服务：
- **科大讯飞** (xfyun) - 默认配置，已集成
- **火山引擎** (volcano) - 可选配置，翻译质量更好
- **自动选择** (auto) - 智能选择最佳可用服务

## 配置方式

### 方式一：使用环境变量（推荐）

在运行应用时设置环境变量：

```bash
# 使用火山引擎
flutter run --dart-define=DEFAULT_ASR_SERVICE=volcano

# 使用科大讯飞
flutter run --dart-define=DEFAULT_ASR_SERVICE=xfyun

# 自动选择（默认）
flutter run --dart-define=DEFAULT_ASR_SERVICE=auto
```

### 方式二：配置火山引擎密钥

火山引擎需要以下配置：

```bash
flutter run \
  --dart-define=VOLCANO_APP_ID=your_app_id \
  --dart-define=VOLCANO_ACCESS_KEY=your_access_key
```

或者在 `app_config.dart` 中直接设置（不推荐）：

```dart
static const String volcanoAppId = String.fromEnvironment(
  'VOLCANO_APP_ID',
  defaultValue: 'your_app_id_here', // 从火山引擎控制台获取
);

static const String volcanoAccessKey = String.fromEnvironment(
  'VOLCANO_ACCESS_KEY',
  defaultValue: 'your_access_key_here', // 从火山引擎控制台获取
);
```

### 方式三：运行时切换

在应用运行时可以通过代码切换：

```dart
// 切换到火山引擎
interpretViewModel.switchAsrService('volcano');

// 切换到科大讯飞
interpretViewModel.switchAsrService('xfyun');
```

## 自动选择逻辑

当 `DEFAULT_ASR_SERVICE=auto` 时：

1. **优先级**：火山引擎 > 科大讯飞
2. **条件检查**：
   - 火山引擎已配置 → 使用火山引擎
   - 科大讯飞已配置 → 使用科大讯飞
   - 都未配置 → 使用科大讯飞（有默认密钥）

## 配置状态检查

应用启动时会显示ASR配置状态：

```
🎯 ASR服务初始化: 使用 volcano (配置: auto)
   火山引擎: 已配置
   科大讯飞: 已配置
```

## 获取火山引擎密钥

1. 访问 [火山引擎控制台](https://console.volcengine.com/speech/service)
2. 创建应用并获取：
   - AppID
   - Access Key
3. 配置到应用中

## 服务对比

| 特性 | 科大讯飞 | 火山引擎 |
|------|---------|---------|
| 识别准确度 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 翻译质量 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 响应速度 | 快 | 快 |
| 配置难度 | 简单（已配置） | 需要申请 |
| 成本 | - | 需要查询定价 |

## 常见问题

**Q: 如何查看当前使用的ASR服务？**
```dart
print(interpretViewModel.state.asrServiceType);
```

**Q: 火山引擎连接失败怎么办？**
- 检查密钥是否正确
- 检查网络连接
- 应用会自动回退到科大讯飞

**Q: 如何禁用某个服务？**
- 将对应的密钥设置为空字符串即可

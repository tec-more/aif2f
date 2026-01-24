# 科大讯飞ASR连接问题诊断与解决

## 问题1：连接成功但立即断开 ❌

### 症状
```
✅ 科大讯飞ASR: WebSocket 连接成功
发送音频数据: 1920 字节 (×8次)
科大讯飞ASR: 连接关闭  ← 刚连接就中断
```

### 原因分析

**音频格式不匹配** - 这是最常见的问题！

| 项目 | 系统声音捕获 | 科大讯飞要求 |
|------|------------|------------|
| 采样率 | 48 kHz | **16 kHz** |
| 声道 | 立体声 (2) | **单声道 (1)** |
| 位深度 | 32-bit Float | 16-bit PCM |

代码中声明格式为 `'format': 'audio/L16;rate=16000'`，但实际发送的是 48kHz 立体声音频。科大讯飞服务器检测到格式不匹配，拒绝处理并关闭连接。

### 解决方案 ✅

已在 `lib/interpret/viewmodel/interpret_view_model.dart` 中修复 `_convertFloatToPcm16` 方法：

```dart
/// 将 IEEE Float 32-bit 转换为 PCM-16
/// 输入: 32-bit float 字节数组（小端序，立体声，48kHz）
/// 输出: 16-bit PCM 字节数组（小端序，单声道，16kHz）
List<int> _convertFloatToPcm16(List<int> floatData) {
  const downsampleFactor = 3;  // 48kHz / 16kHz = 3
  final outputFrameCount = inputFrameCount ~/ downsampleFactor;

  for (int i = 0; i < outputFrameCount; i++) {
    // 1. 降采样：每隔 3 个样本取 1 个
    final inputFrameIndex = i * downsampleFactor;

    // 2. 只取左声道（立体声 → 单声道）
    final sampleStartIndex = inputFrameIndex * 8;

    // 3. 32-bit Float → 16-bit PCM
    final floatValue = _ieee754BitsToFloat(bits);
    final pcmValue = (floatValue.clamp(-1.0, 1.0) * 32767).toInt();
    // ...
  }
}
```

### 验证修复 ✅

修复后应该看到：

```
✅ 科大讯飞ASR: WebSocket 连接成功
发送音频数据: 640 字节  ← 数据量约为之前的 1/3 (48kHz→16kHz, 立体声→单声道)
科大讯飞ASR: 识别到文字 (0): 你
科大讯飞ASR: 识别到文字 (1): 你好
科大讯飞ASR识别结果: 你好
```

---

## 问题2：科大讯飞ASR: 未连接

### 症状
```
科大讯飞ASR: 未连接
科大讯飞ASR: 未连接
科大讯飞ASR: 未连接
```

### 原因分析

这个问题是由以下原因造成的：

1. **WebSocket连接未建立完成**
   - `connect()` 方法立即返回，但WebSocket还在连接中
   - 音频数据开始发送，但此时 `_isConnected` 仍然是 `false`
   - 每次尝试发送音频都会打印"未连接"

2. **可能的连接失败原因**
   - API密钥配置错误
   - 网络问题
   - WebSocket URL不正确
   - 签名算法错误
   - 服务器拒绝连接

### 已修复的问题

#### 修复1: 等待连接真正建立

**文件**: `lib/core/services/ai_asr.dart`

**修改前**:
```dart
_wsChannel!.ready.then((_) {
  _isConnected = true;
  debugPrint('科大讯飞ASR: 连接成功');
  onConnected?.call();
});
return true; // 立即返回
```

**修改后**:
```dart
// 等待连接真正建立
await _wsChannel!.ready.then((_) {
  _isConnected = true;
  debugPrint('科大讯飞ASR: 连接成功');
  onConnected?.call();
}).timeout(
  const Duration(seconds: 10),
  onTimeout: () {
    debugPrint('科大讯飞ASR: 连接超时');
    throw Exception('连接超时');
  },
);
return _isConnected;
```

#### 修复2: 先设置回调再连接

**文件**: `lib/interpret/viewmodel/interpret_view_model.dart`

**修改前**:
```dart
_xfyunAsrService.connect(); // 先连接
// 然后设置回调
_xfyunAsrService.onTextRecognized = (text) { ... };
```

**修改后**:
```dart
// 先设置所有回调
_xfyunAsrService.onTextRecognized = (text) { ... };
_xfyunAsrService.onError = (error) { ... };
_xfyunAsrService.onConnected = () { ... };
_xfyunAsrService.onDisconnected = () { ... };

// 然后等待连接成功
final connected = await _xfyunAsrService.connect();
```

---

## 诊断步骤

### 1. 检查配置是否正确

查看控制台输出，确认配置已加载：

```
科大讯飞ASR服务初始化:
  APPID: 45f8b6dc
  APIKey: d1e278f...
  URL: wss://ws-api.xf-yun.com/v1/private/simult_interpretation
```

**检查要点**:
- APPID 不为空
- APIKey 不为空
- URL 正确

### 2. 检查连接过程

查看连接日志：

```
正在连接科大讯飞ASR: wss://ws-api.xf-yun.com/v1/private/simult_interpretation
APPID: 45f8b6dc
WebSocket URL: wss://ws-api.xf-yun.com/v1/private/simult_interpretation?appid=45f8b6dc&timestamp=...
科大讯飞ASR: 连接成功  <-- 应该看到这条
```

**如果看到错误**:
```
科大讯飞ASR: 连接失败: ...
```

### 3. 常见错误及解决方案

#### 错误1: 连接超时

```
科大讯飞ASR: 连接超时
```

**解决方案**:
1. 检查网络连接
2. 确认可以访问 `ws-api.xf-yun.com`
3. 检查防火墙设置
4. 尝试使用VPN

#### 错误2: 签名验证失败

```
科大讯飞ASR: 错误 (10407): 签名验证失败
```

**解决方案**:
1. 确认 `APPID`、`APIKey`、`APISecret` 正确
2. 检查是否过期
3. 重新生成密钥

#### 错误3: 应用不存在

```
科大讯飞ASR: 错误 (10009): 应用不存在
```

**解决方案**:
1. 登录科大讯飞开放平台
2. 确认应用已创建
3. 确认APPID正确

#### 错误4: 额度不足

```
科大讯飞ASR: 错误 (10406): 额度不足
```

**解决方案**:
1. 检查账户余额
2. 充值或升级套餐

### 4. 测试API密钥

使用 curl 测试连接：

```bash
# 生成时间戳和签名
TIMESTAMP=$(date +%s)
SIGNATURE=$(echo -n "YOUR_APPID${TIMESTAMP}YOUR_APIKEY" | md5sum | cut -d' ' -f1)

# 测试WebSocket连接
wscat -c "wss://ws-api.xf-yun.com/v1/private/simult_interpretation?appid=YOUR_APPID&timestamp=${TIMESTAMP}&signature=${SIGNATURE}"
```

### 5. 检查音频格式

科大讯飞要求：
- **采样率**: 16kHz
- **位深度**: 16-bit
- **声道**: 单声道

当前代码：
- 系统音频: 48kHz, 32-bit Float, 立体声
- 自动转换为: 16kHz, 16-bit PCM

**验证转换代码**:
```dart
// interpret_view_model.dart
if (_outputAsPcm16) {
  dataToWrite = _convertFloatToPcm16(audioData); // 应该是true
}
```

---

## 验证修复

### 预期的正常日志

```
正在连接科大讯飞ASR: wss://ws-api.xf-yun.com/v1/private/simult_interpretation
APPID: 45f8b6dc
WebSocket URL: wss://ws-api.xf-yun.com/v1/private/simult_interpretation?appid=45f8b6dc&timestamp=...
科大讯飞ASR: 连接成功
科大讯飞ASR已连接
ASR已连接，正在识别...
发送音频数据: 3200 字节
发送音频数据: 3200 字节
科大讯飞ASR: 识别到文字 (0): 你
科大讯飞ASR: 识别到文字 (1): 你好
科大讯飞ASR: 识别到文字 (2): 你好世界
科大讯飞ASR识别结果: 你好世界
```

### 测试步骤

1. **重新运行应用**:
   ```bash
   flutter run
   ```

2. **启动系统声音捕获**:
   - 点击按钮开始捕获
   - 观察控制台日志

3. **播放音频/说话**:
   - 播放一段音乐或说话
   - 查看是否看到识别结果

4. **检查状态**:
   - 应该显示 "ASR已连接，正在识别..."
   - 不应该再看到 "ASR: 未连接"

---

## 临时禁用ASR

如果ASR仍然有问题，可以暂时禁用它：

**文件**: `lib/interpret/viewmodel/interpret_view_model.dart`

```dart
// 在 InterpretViewModel 类中
bool _enableRealtimeAsr = false; // 改为 false
```

这样音频捕获仍然工作，但不会尝试连接ASR服务。

---

## 获取帮助

如果问题仍然存在：

1. **收集日志**:
   - 完整的控制台输出
   - 包括连接日志和错误信息

2. **检查配置**:
   - APPID、APIKey、APISecret
   - 不要泄露完整密钥

3. **网络测试**:
   ```bash
   # 测试DNS解析
   nslookup ws-api.xf-yun.com

   # 测试连通性
   ping ws-api.xf-yun.com

   # 测试HTTPS
   curl -I https://ws-api.xf-yun.com
   ```

4. **联系支持**:
   - 科大讯飞技术支持: https://www.xfyun.cn/
   - 查看文档: https://www.xfyun.cn/doc/

---

## 相关文档

- [科大讯飞ASR使用指南](XFYUN_ASR_GUIDE.md)
- [翻译设置指南](TRANSLATION_SETUP_GUIDE.md)
- [Azure语音服务集成指南](AZURE_SPEECH_GUIDE.md)

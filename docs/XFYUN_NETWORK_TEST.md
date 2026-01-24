# 科大讯飞 ASR 连接问题诊断

## 问题1：连接成功但立即断开

### 症状
```
✅ 科大讯飞ASR: WebSocket 连接成功
发送音频数据: 1920 字节 (×8次)
科大讯飞ASR: 连接关闭  ← 刚连接就中断
```

### 原因

**音频格式不匹配**：
- 实际发送：48kHz, 立体声, 16-bit PCM
- 声称格式：`audio/L16;rate=16000` (16kHz, 单声道)
- 科大讯飞服务器检测到格式不匹配，拒绝音频并关闭连接

### 解决方案

已在 `interpret_view_model.dart` 中修复 `_convertFloatToPcm16` 方法：

1. **降采样**：48kHz → 16kHz (保留 1/3 样本)
2. **单声道**：只取左声道
3. **格式**：32-bit Float → 16-bit PCM

**修改前**：
```dart
// 只转换格式，不降采样，不转单声道
List<int> _convertFloatToPcm16(List<int> floatData) {
  final sampleCount = floatData.length ~/ 4;
  // ... 处理所有样本 ...
}
```

**修改后**：
```dart
// 1. 降采样 (48kHz → 16kHz)
// 2. 立体声 → 单声道
// 3. 32-bit Float → 16-bit PCM
const downsampleFactor = 3;
final outputFrameCount = inputFrameCount ~/ downsampleFactor;

for (int i = 0; i < outputFrameCount; i++) {
  // 只取左声道
  final inputFrameIndex = i * downsampleFactor;
  // ...
}
```

### 验证

重新运行后应该看到：
```
✅ 科大讯飞ASR: WebSocket 连接成功
发送音频数据: 640 字节  ← 数据量减少 (约1/3)
科大讯飞ASR: 识别到文字 (0): 你
科大讯飞ASR: 识别到文字 (1): 你好
```

---

## 问题2：连接超时

### 症状

```
科大讯飞ASR: 连接超时（30秒）
科大讯飞ASR: 未连接（重复多次）
科大讯飞ASR已连接  ← 最终成功连接
```

## 诊断步骤

### 1. 测试网络连通性

#### Windows (PowerShell)
```powershell
# 测试 DNS 解析
nslookup ws-api.xf-yun.com

# 测试连通性
Test-NetConnection -ComputerName ws-api.xf-yun.com -Port 443

# Ping 测试
ping ws-api.xf-yun.com
```

#### Linux/macOS
```bash
# 测试 DNS 解析
nslookup ws-api.xf-yun.com

# 测试连通性
nc -zv ws-api.xf-yun.com 443

# Ping 测试
ping ws-api.xf-yun.com
```

### 2. 测试 WebSocket 连接

使用在线工具测试：
- https://www.piesocket.com/websocket-tester
- 连接到: `wss://ws-api.xf-yun.com/v1/private/simult_interpretation`

### 3. 常见问题

#### 问题1: 防火墙阻止
**症状**: 连接超时
**解决**:
- Windows: 允许 `flutter.exe` 通过防火墙
- 添加端口 443 (HTTPS/WSS) 到允许列表

#### 问题2: 需要代理/VPN
**症状**: 无法访问 `ws-api.xf-yun.com`
**解决**:
- 检查是否需要 VPN 访问科大讯飞服务
- 配置系统代理

#### 问题3: API 密钥错误
**症状**: 401 认证失败
**解决**:
- 登录科大讯飞控制台
- 检查 API 密钥是否正确
- 确认服务已开通

## 调试建议

### 启用详细日志

当前代码已添加详细日志，请观察：

```
正在连接科大讯飞ASR: wss://ws-api.xf-yun.com/...
APPID: 45f8b6dc
签名原始字段:
host: ws-api.xf-yun.com
date: Fri, 23 Jan 2026 16:15:18 GMT
GET /v1/private/simult_interpretation HTTP/1.1
签名结果: xxx
Authorization 原始: api_key="xxx", ...
正在建立 WebSocket 连接，最长等待 30 秒...
```

### 如果连接成功

应该看到：
```
✅ 科大讯飞ASR: WebSocket 连接成功
开始监听 WebSocket 消息...
科大讯飞ASR: connect() 返回，连接状态: true
```

### 如果连接失败

会看到：
```
❌ 科大讯飞ASR: 连接超时（30秒）
可能原因：
  1. 无法访问 ws-api.xf-yun.com（网络问题/防火墙）
  2. API 密钥配置错误
  3. 需要使用 VPN
```

## 替代方案

如果科大讯飞无法连接，可以：

### 方案1: 使用 Azure Speech Services

```dart
// 修改 interpret_view_model.dart
final _asrService = AzureRealtimeSpeechService(); // 替换 XfyunRealtimeAsrService
```

### 方案2: 仅保存音频，稍后识别

```dart
// 当前实现已支持
// 即使 ASR 连接失败，音频仍会保存到文件
```

## 临时禁用 ASR

如果网络问题持续，可以临时禁用实时 ASR：

```dart
// 在 InterpretViewModel 中
bool _enableRealtimeAsr = false; // 设置为 false
```

这样：
- ✅ 音频仍然会捕获并保存
- ✅ 不会尝试连接 ASR 服务
- ✅ 不会显示 "ASR: 未连接" 日志

## 测试建议

1. **先测试网络**:
   ```bash
   ping ws-api.xf-yun.com
   ```

2. **清理缓存重试**:
   ```bash
   flutter clean
   flutter run
   ```

3. **观察完整日志**:
   - 重点关注连接阶段的前 30 秒
   - 查看是否有错误信息

4. **检查防火墙**:
   - Windows: 控制面板 → 系统和安全 → Windows Defender 防火墙
   - 允许应用通过防火墙

## 长期解决方案

### 网络优化

如果网络不稳定，考虑：

1. **增加重试机制**:
   ```dart
   int retryCount = 0;
   const maxRetries = 3;

   while (retryCount < maxRetries) {
     final connected = await _xfyunAsrService.connect();
     if (connected) break;
     retryCount++;
     await Future.delayed(Duration(seconds: 5));
   }
   ```

2. **超时自适应**:
   ```dart
   // 根据网络状况调整超时时间
   Duration timeout = _isNetworkFast() ? Duration(seconds: 10) : Duration(seconds: 60);
   ```

3. **离线模式**:
   ```dart
   // 检测到网络不可用时，自动切换到仅保存模式
   if (!await _checkNetworkAvailable()) {
     _enableRealtimeAsr = false;
   }
   ```

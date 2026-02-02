# AI面对面 - 后端集成说明

## 概述

本文档说明 Flutter 应用与 FastAPI 后端 (aipaneladmin) 的集成情况。

## 后端项目信息

- **项目路径**: `D:\Programs\fastapi\aipaneladmin`
- **API 地址**: `http://127.0.0.1:9999`
- **API 文档**: http://127.0.0.1:9999/docs
- **API 版本**: v1

## 集成模块

### 1. 用户认证模块

#### API 端点

| 功能 | 方法 | 端点 | 说明 |
|------|------|------|------|
| 用户注册 | POST | `/api/v1/auth/register` | 注册新用户 |
| 用户登录 | POST | `/api/v1/auth/login` | 用户登录获取 Token |
| 获取当前用户 | GET | `/api/v1/auth/me` | 获取当前登录用户信息 |
| 修改密码 | POST | `/api/v1/auth/change-password` | 修改当前用户密码 |
| 用户登出 | POST | `/api/v1/auth/logout` | 用户登出 |

#### 请求/响应格式

**注册请求**:
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}
```

**登录请求**:
```json
{
  "username": "testuser",
  "password": "password123"
}
```

**登录响应**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "is_active": true,
    "is_superuser": false
  }
}
```

**修改密码请求**:
```json
{
  "old_password": "oldpass123",
  "new_password": "newpass123"
}
```

#### Flutter 实现

- **模型**: [lib/data/models/user_model.dart](lib/data/models/user_model.dart)
- **服务**: [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart)
- **状态管理**: [lib/data/providers/auth_provider.dart](lib/data/providers/auth_provider.dart)
- **存储**: [lib/data/services/token_storage_service.dart](lib/data/services/token_storage_service.dart)
- **UI**: [lib/user/widgets/login_dialog.dart](lib/user/widgets/login_dialog.dart)

**使用示例**:
```dart
// 检查登录状态
final isLoggedIn = await checkLogin(context, ref);

if (isLoggedIn) {
  // 用户已登录，执行操作
}
```

### 2. 支付模块

#### API 端点

**支付宝支付**:

| 功能 | 方法 | 端点 | 说明 |
|------|------|------|------|
| 创建订单 | POST | `/api/v1/pay/alipay/orders` | 创建支付宝支付订单 |
| 查询订单 | GET | `/api/v1/pay/alipay/orders/{order_id}` | 查询订单状态 |
| 申请退款 | POST | `/api/v1/pay/alipay/refunds` | 申请退款 |
| 支付通知 | POST | `/api/v1/pay/alipay/notify` | 支付宝异步通知 |

**微信支付**:

| 功能 | 方法 | 端点 | 说明 |
|------|------|------|------|
| 创建订单 | POST | `/api/v1/pay/wechat/orders` | 创建微信支付订单 |
| 查询订单 | GET | `/api/v1/pay/wechat/orders/{order_id}` | 查询订单状态 |
| 申请退款 | POST | `/api/v1/pay/wechat/refunds` | 申请退款 |
| 支付通知 | POST | `/api/v1/pay/wechat/notify` | 微信异步通知 |

#### 请求/响应格式

**创建订单请求**:
```json
{
  "out_trade_no": "RECHARGE1234567890",
  "total_amount": 99.9,
  "subject": "账户充值",
  "body": "充值金额: ¥99.90"
}
```

**支付宝订单响应**:
```json
{
  "order_id": "2025020222001234567890123456",
  "qr_code": "https://qr.alipay.com/xxx",
  "trade_status": "WAIT_BUYER_PAY"
}
```

**微信订单响应**:
```json
{
  "order_id": "1234567890",
  "code_url": "weixin://wxpay/bizpayurl?pr=xxx",
  "prepay_id": "wx261xxx",
  "trade_state": "NOTPAY"
}
```

#### Flutter 实现

- **模型**: [lib/data/models/payment_model.dart](lib/data/models/payment_model.dart)
- **服务**: [lib/data/services/payment_service.dart](lib/data/services/payment_service.dart)
- **状态管理**: [lib/data/providers/payment_provider.dart](lib/data/providers/payment_provider.dart)
- **UI**: [lib/user/widgets/recharge_dialog.dart](lib/user/widgets/recharge_dialog.dart)

**使用示例**:
```dart
// 创建订单
final order = await ref.read(paymentProvider.notifier).createPaymentOrder(
  outTradeNo: 'RECHARGE${DateTime.now().millisecondsSinceEpoch}',
  amount: 99.9,
  subject: '账户充值',
  body: '充值金额: ¥99.90',
  type: PaymentType.alipay,
);
```

### 3. Token 持久化

应用使用 `shared_preferences` 存储 Token，实现自动登录功能。

**存储内容**:
- `auth_token`: JWT 访问令牌
- `user_id`: 用户 ID
- `username`: 用户名

**存储位置**:
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);
await prefs.setInt('user_id', userId);
await prefs.setString('username', username);
```

## 配置说明

### API 配置

**文件**: [lib/core/config/api_config.dart](lib/core/config/api_config.dart)

```dart
class ApiConfig {
  // API 基础地址（可通过环境变量覆盖）
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9999',
  );

  // API 版本
  static const String apiVersion = '/api/v1';
}
```

### 环境变量

可以在编译时设置不同的 API 地址：

```bash
# 开发环境
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9999

# 生产环境
flutter build windows --dart-define=API_BASE_URL=https://api.yourdomain.com
```

## 数据流

### 用户登录流程

```
用户输入 → LoginDialog → AuthNotifier.login()
    ↓
AuthService.login() → API: POST /api/v1/auth/login
    ↓
后端验证 → 返回 Token + 用户信息
    ↓
存储到本地 → TokenStorageService
    ↓
更新状态 → AuthState.authenticated
```

### 支付流程

```
用户选择金额 → RechargeDialog → PaymentNotifier.createPaymentOrder()
    ↓
PaymentService → API: POST /api/v1/pay/{type}/orders
    ↓
后端创建订单 → 返回支付信息（二维码/URL）
    ↓
用户支付 → PaymentNotifier.pollOrderStatus()
    ↓
轮询查询 → API: GET /api/v1/pay/{type}/orders/{id}
    ↓
支付成功 → 更新应用状态
```

## 已实现功能

✅ **用户认证**
- [x] 用户注册
- [x] 用户登录
- [x] 自动登录（Token 持久化）
- [x] 获取当前用户信息
- [x] 修改密码
- [x] 用户登出

✅ **支付功能**
- [x] 创建支付宝订单
- [x] 创建微信订单
- [x] 查询订单状态
- [x] 订单状态轮询
- [x] 申请退款（接口已实现）

✅ **UI 组件**
- [x] 登录对话框
- [x] 充值对话框
- [x] 登录检查辅助函数

## 待完成功能

⏳ **支付功能**
- [ ] 七相支付平台集成（配置文件已存在）
- [ ] 支付宝/微信支付实际支付流程测试
- [ ] 支付结果通知处理

⏳ **用户功能**
- [ ] 个人资料页面
- [ ] 设置页面
- [ ] 头像上传
- [ ] 会员系统集成

## 注意事项

1. **API 地址**: 开发环境使用 `http://127.0.0.1:9999`，生产环境请通过环境变量配置
2. **Token 管理**: Token 存储在本地，有效期由后端控制
3. **错误处理**: 所有 API 调用都有错误处理和用户提示
4. **状态管理**: 使用 Riverpod 3.x 进行状态管理
5. **登录验证**: 使用 `checkLogin()` 函数检查用户登录状态

## 测试

### 启动后端服务

```bash
cd D:\Programs\fastapi\aipaneladmin
python -m uvicorn main:app --reload --port 9999
```

### 启动 Flutter 应用

```bash
cd D:\Programs\flutter\ai\aif2f
flutter run -d windows
```

### 测试用户认证

1. 打开应用
2. 点击录音按钮或会员功能
3. 在登录对话框中输入：
   - 用户名: test
   - 密码: test123
4. 点击登录

### 测试支付功能

1. 登录后点击侧边栏充值按钮
2. 选择充值金额
3. 选择支付方式（支付宝/微信）
4. 查看支付信息

## 故障排除

### API 连接失败

1. 检查后端服务是否启动
2. 检查 API 地址是否正确
3. 查看控制台日志（`kDebugMode` 会输出详细请求信息）

### Token 过期

- Token 过期后会自动跳转到登录页
- 重新登录即可获取新 Token

### 支付订单问题

- 检查订单号是否唯一
- 检查金额格式是否正确
- 查看后端日志确认订单创建状态

## 联系方式

如有问题，请查看：
- 后端 API 文档: http://127.0.0.1:9999/docs
- Flutter 控制台日志
- 后端服务日志

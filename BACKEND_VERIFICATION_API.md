# 后端验证码 API 实现文档

## 概述

为了支持用户注册时的邮箱验证码功能，需要在 FastAPI 后端添加以下API接口。

## 需要实现的API端点

### 1. 发送验证码

**端点**: `POST /api/v1/auth/send-code`

**请求体**:
```json
{
  "email": "user@example.com",
  "type": "register"
}
```

**type 参数说明**:
- `register` - 注册验证码
- `reset_password` - 重置密码验证码
- `bind_email` - 绑定邮箱验证码
- `bind_phone` - 绑定手机验证码

**响应**:
```json
{
  "success": true,
  "message": "验证码已发送",
  "expires_in": 300
}
```

**实现示例**:

```python
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
import random
from typing import Optional

router = APIRouter(prefix="/auth", tags=["认证"])

# 存储验证码（生产环境应使用Redis）
verification_codes = {}

class SendCodeRequest(BaseModel):
    email: EmailStr
    type: str  # register, reset_password, bind_email, bind_phone

class SendCodeResponse(BaseModel):
    success: bool
    message: str
    expires_in: Optional[int] = None

@router.post("/send-code", response_model=SendCodeResponse)
async def send_verification_code(request: SendCodeRequest):
    """
    发送验证码到邮箱

    - 生成6位数字验证码
    - 发送到用户邮箱
    - 验证码有效期5分钟
    - 同一邮箱60秒内只能发送一次
    """
    email = request.email
    code_type = request.type

    # 检查发送频率限制
    key = f"{email}_{code_type}"
    if key in verification_codes:
        last_sent = verification_codes[key]["timestamp"]
        if datetime.now() - last_sent < timedelta(seconds=60):
            raise HTTPException(
                status_code=400,
                detail="验证码发送过于频繁，请60秒后再试"
            )

    # 生成6位数字验证码
    code = str(random.randint(100000, 999999))

    # TODO: 实际发送邮件（使用SMTP或邮件服务）
    # await send_email(email, code, code_type)
    print(f"发送验证码到 {email}: {code}")  # 调试用，实际环境删除

    # 存储验证码（有效期5分钟）
    verification_codes[key] = {
        "code": code,
        "timestamp": datetime.now(),
        "expires_at": datetime.now() + timedelta(minutes=5)
    }

    return SendCodeResponse(
        success=True,
        message="验证码已发送",
        expires_in=300
    )
```

### 2. 验证验证码

**端点**: `POST /api/v1/auth/verify-code`

**请求体**:
```json
{
  "email": "user@example.com",
  "code": "123456",
  "type": "register"
}
```

**响应**:
```json
{
  "success": true,
  "valid": true
}
```

**实现示例**:

```python
class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str
    type: str

class VerifyCodeResponse(BaseModel):
    success: bool
    valid: bool
    message: Optional[str] = None

@router.post("/verify-code", response_model=VerifyCodeResponse)
async def verify_code(request: VerifyCodeRequest):
    """
    验证邮箱验证码

    - 检查验证码是否正确
    - 检查验证码是否过期
    """
    email = request.email
    code = request.code
    code_type = request.type

    key = f"{email}_{code_type}"

    if key not in verification_codes:
        return VerifyCodeResponse(
            success=False,
            valid=False,
            message="验证码不存在或已过期"
        )

    stored_data = verification_codes[key]

    # 检查是否过期
    if datetime.now() > stored_data["expires_at"]:
        del verification_codes[key]
        return VerifyCodeResponse(
            success=False,
            valid=False,
            message="验证码已过期"
        )

    # 验证码匹配
    if stored_data["code"] != code:
        return VerifyCodeResponse(
            success=False,
            valid=False,
            message="验证码错误"
        )

    # 验证成功，删除验证码
    del verification_codes[key]

    return VerifyCodeResponse(
        success=True,
        valid=True,
        message="验证码验证成功"
    )
```

### 3. 修改注册接口

在用户注册时添加验证码验证：

```python
class RegisterRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    verification_code: Optional[str] = None  # 新增验证码字段

@router.post("/register")
async def register(request: RegisterRequest):
    """
    用户注册（需要邮箱验证码）
    """
    # 检查用户名是否已存在
    # ...

    # 如果提供了验证码，验证验证码
    if request.verification_code:
        verify_req = VerifyCodeRequest(
            email=request.email,
            code=request.verification_code,
            type="register"
        )
        verify_result = await verify_code(verify_req)
        if not verify_result.valid:
            raise HTTPException(
                status_code=400,
                detail=verify_result.message or "验证码验证失败"
            )

    # 创建用户
    # ...

    return {"user": user_dict}
```

## 邮件发送实现

### 使用 SMTP 发送邮件

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "your-email@gmail.com")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "your-app-password")

async def send_email(to_email: str, code: str, code_type: str):
    """
    发送验证码邮件
    """
    subject = "AI面对面 - 邮箱验证码"

    if code_type == "register":
        body = f"""
您好，

您的注册验证码是：{code}

验证码有效期为5分钟，请尽快完成注册。

如果这不是您的操作，请忽略此邮件。

---
AI面对面团队
        """
    elif code_type == "reset_password":
        body = f"""
您好，

您的密码重置验证码是：{code}

验证码有效期为5分钟，请尽快完成密码重置。

如果这不是您的操作，请忽略此邮件。

---
AI面对面团队
        """
    else:
        body = f"您的验证码是：{code}"

    msg = MIMEMultipart()
    msg['From'] = SMTP_USER
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
            print(f"邮件已发送到 {to_email}")
    except Exception as e:
        print(f"邮件发送失败: {e}")
        raise
```

## 环境变量配置

在 `.env` 文件中添加：

```bash
# SMTP 邮件配置
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# 或者使用其他邮件服务
# SMTP_HOST=smtp.qq.com
# SMTP_PORT=587
```

## 使用邮件服务（推荐）

对于生产环境，建议使用专业邮件服务：

### 1. SendGrid

```python
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")

async def send_email(to_email: str, code: str, code_type: str):
    message = Mail(
        from_email=SMTP_USER,
        to_emails=to_email,
        subject="AI面对面 - 邮箱验证码",
        html_content=f"<strong>您的验证码是：{code}</strong>"
    )

    sg = SendGridAPIClient(SENDGRID_API_KEY)
    response = sg.send(message)
    return response.status_code == 202
```

### 2. 阿里云邮件推送

```python
from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ServerException
from alibabacloud_dm20151123 import Client as DmClient
from alibabacloud_dm20151123.models import SingleSendMailRequest

DM_ACCESS_KEY_ID = os.getenv("DM_ACCESS_KEY_ID")
DM_ACCESS_KEY_SECRET = os.getenv("DM_ACCESS_KEY_SECRET")
DM_ACCOUNT_NAME = os.getenv("DM_ACCOUNT_NAME")

async def send_email(to_email: str, code: str, code_type: str):
    client = DmClient(
        access_key_id=DM_ACCESS_KEY_ID,
        access_key_secret=DM_ACCESS_KEY_SECRET
    )

    request = SingleSendMailRequest(
        account_name=DM_ACCOUNT_NAME,
        address_type=1,
        reply_to_address=SMTP_USER,
        to_address=to_email,
        subject="AI面对面 - 邮箱验证码",
        html_body=f"<strong>您的验证码是：{code}</strong>"
    )

    response = client.single_send_mail_with_options(request)
    return response.status_code == 200
```

## 生产环境注意事项

### 1. 使用 Redis 存储验证码

```python
import redis
from typing import Optional

redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    db=0,
    decode_responses=True
)

async def save_code(email: str, code: str, code_type: str):
    key = f"verification_code:{code_type}:{email}"
    await redis_client.setex(key, 300, code)  # 5分钟过期

async def get_code(email: str, code_type: str) -> Optional[str]:
    key = f"verification_code:{code_type}:{email}"
    return await redis_client.get(key)

async def delete_code(email: str, code_type: str):
    key = f"verification_code:{code_type}:{email}"
    await redis_client.delete(key)
```

### 2. 添加限流机制

```python
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter

@router.post("/send-code", dependencies=[Depends(RateLimiter(times=5, seconds=60))])
async def send_verification_code(request: SendCodeRequest):
    # 同一IP每分钟最多发送5次
    pass
```

### 3. 异步任务

使用 Celery 或 BackgroundTasks 异步发送邮件：

```python
from fastapi import BackgroundTasks

def send_email_task(to_email: str, code: str, code_type: str):
    # 异步发送邮件
    pass

@router.post("/send-code")
async def send_verification_code(
    request: SendCodeRequest,
    background_tasks: BackgroundTasks
):
    # 生成验证码
    code = str(random.randint(100000, 999999))

    # 异步发送邮件
    background_tasks.add_task(send_email_task, request.email, code, request.type)

    # ...
```

## 测试

### 发送验证码测试

```bash
curl -X POST "http://127.0.0.1:9999/api/v1/auth/send-code" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "type": "register"
  }'
```

### 验证验证码测试

```bash
curl -X POST "http://127.0.0.1:9999/api/v1/auth/verify-code" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "123456",
    "type": "register"
  }'
```

## 总结

1. ✅ 前端已实现验证码UI（输入框、发送按钮、倒计时）
2. ⏳ 后端需要实现上述API端点
3. ⏳ 需要配置邮件发送服务
4. ⏳ 建议使用 Redis 存储验证码（生产环境）

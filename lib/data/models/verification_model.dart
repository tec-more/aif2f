/// 验证码类型
enum VerificationCodeType {
  login('登录'),
  register('注册'),
  resetPassword('重置密码'),
  bindEmail('绑定邮箱'),
  bindPhone('绑定手机');

  final String displayName;
  const VerificationCodeType(this.displayName);
}

/// 验证码响应模型
class VerificationCodeResponse {
  final bool success;
  final String? message;
  final int? expiresIn; // 过期时间（秒）

  VerificationCodeResponse({
    required this.success,
    this.message,
    this.expiresIn,
  });

  factory VerificationCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerificationCodeResponse(
      success: json['success'] as bool? ?? json['status'] == 'success',
      message: json['message'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }
}

/// 验证码验证请求
class VerifyCodeRequest {
  final String email;
  final String code;
  final VerificationCodeType type;

  VerifyCodeRequest({
    required this.email,
    required this.code,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'type': type.name,
    };
  }
}

/// 发送验证码请求
class SendCodeRequest {
  final String email;
  final VerificationCodeType type;

  SendCodeRequest({
    required this.email,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'type': type.name,
    };
  }
}

/// 用户模型
class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// 累计充值时长（小时）
  final int totalHours;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.nickname,
    this.avatar,
    this.phone,
    required this.isActive,
    required this.isSuperuser,
    this.createdAt,
    this.updatedAt,
    this.totalHours = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isSuperuser: json['is_superuser'] as bool? ?? json['isSuperuser'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null),
      totalHours: json['total_hours'] as int? ?? json['totalHours'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_hours': totalHours,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? nickname,
    String? avatar,
    String? phone,
    bool? isActive,
    bool? isSuperuser,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalHours,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalHours: totalHours ?? this.totalHours,
    );
  }
}

/// 客户登录请求模型
class CustomerLogin {
  final String email;
  final String password;

  CustomerLogin({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// 客户验证码登录请求模型
class CustomerLoginCode {
  final String email;
  final String code;

  CustomerLoginCode({required this.email, required this.code});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}

/// 登录请求模型（兼容旧接口）
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

/// 注册请求模型
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String code; // 验证码（必填）
  final String? nickname;
  final String? phone;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.code,
    this.nickname,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'code': code,
      if (nickname != null) 'nickname': nickname,
      if (phone != null) 'phone': phone,
    };
  }
}

/// 修改密码请求模型
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({required this.oldPassword, required this.newPassword});

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
    };
  }
}

/// Token 响应模型
class TokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    // 支持 user 和 customer 两种字段名
    final userJson = json['user'] as Map<String, dynamic>? ??
                    json['customer'] as Map<String, dynamic>?;

    if (userJson == null) {
      throw Exception('响应数据中缺少 user 或 customer 字段');
    }

    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
      user: UserModel.fromJson(userJson),
    );
  }
}

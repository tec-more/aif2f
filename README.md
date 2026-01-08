# AI面对面

一个基于Flutter的跨平台应用，支持传译、场景选择等功能。

## 功能特性

- **首页**：应用主界面
- **传译**：翻译和口译功能
- **场景**：预设场景选择
- **我的**：用户个人中心

## 响应式设计

应用采用响应式设计，根据屏幕尺寸自动切换导航模式：
- 宽屏（≥600px）：左侧边栏导航
- 窄屏（<600px）：底部导航栏

## 项目结构

```
lib/
├── home/             # 首页模块
│   ├── design/       # UI组件
│   ├── model/        # 数据模型
│   └── interaction/  # 业务逻辑
├── interpret/        # 传译模块
│   ├── design/       # UI组件
│   ├── model/        # 数据模型
│   └── interaction/  # 业务逻辑
├── scene/            # 场景模块
│   ├── design/       # UI组件
│   ├── model/        # 数据模型
│   └── interaction/  # 业务逻辑
├── profile/          # 个人中心模块
│   ├── design/       # UI组件
│   ├── model/        # 数据模型
│   └── interaction/  # 业务逻辑
└── main.dart         # 应用入口
```

## 构建和运行

### Windows

```bash
flutter build windows
```

构建完成后，可执行文件位于：`build/windows/x64/runner/Release/aif2f.exe`

### 其他平台

```bash
flutter run
```

## 技术栈

- Flutter
- Dart
- 响应式设计
- 模块化架构

## 开发说明

- 所有UI组件、数据模型和业务逻辑都遵循模块化设计原则
- 使用MediaQuery实现响应式布局
- 遵循Flutter最佳实践和代码规范

#!/usr/bin/env dart

/// 路由常量生成器
/// 从各个模块的 view 目录扫描 @RoutePage 注解，自动生成 AppRoutes 常量类
///
/// 使用方法：
/// dart tool/generate_routes_constants.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

final _logger = Logger('RouteGenerator');

void main() {
  _logger.info('🔍 正在扫描路由页面...\n');

  // 查找所有带有 @RoutePage 注解的页面
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    _logger.info('❌ 错误: 找不到 lib 目录');
    exit(1);
  }

  // 收集所有路由页面
  final routePages = <RoutePageInfo>[];

  // 扫描各个模块的 view 目录
  final modules = ['interpret', 'scene', 'user', 'core'];

  for (final module in modules) {
    // 尝试多个可能的目录位置
    final possibleDirs = [
      Directory(p.join('lib', module, 'view')),
      Directory(p.join('lib', module)), // 某些模块可能直接在模块根目录
    ];

    Directory? targetDir;
    for (final dir in possibleDirs) {
      if (dir.existsSync()) {
        targetDir = dir;
        break;
      }
    }

    if (targetDir == null) {
      _logger.info('⚠️  跳过不存在的模块: $module');
      continue;
    }

    final files = targetDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('.gr.dart'))
        .toList();

    for (final file in files) {
      final content = file.readAsStringSync();

      // 检查是否包含 @RoutePage 注解
      if (content.contains('@RoutePage(') || content.contains('@RoutePage()')) {
        // 提取类名
        final classNameMatch = RegExp(
          r'class\s+(\w+)\s+extends',
        ).firstMatch(content);
        if (classNameMatch != null) {
          final className = classNameMatch.group(1)!;

          // 提取自定义路由名称（如果有）
          final routeNameMatch = RegExp(
            r"@RoutePage\(\s*name:\s*'([^']+)'",
          ).firstMatch(content);
          final routeName = routeNameMatch != null
              ? routeNameMatch.group(1)!
              : _toRouteName(className);

          final routePath = _generateRoutePath(module, className);

          routePages.add(
            RoutePageInfo(
              className: className,
              routeName: routeName,
              routePath: routePath,
              module: module,
              importPath: _getImportPath(file.path),
            ),
          );

          _logger.info('✅ 找到路由页面: $className -> $routeName');
        }
      }
    }
  }

  _logger.info('\n📝 共找到 ${routePages.length} 个路由页面\n');

  // 生成 AppRoutes 类
  final output = _generateAppRoutesClass(routePages);

  // 写入 app_router.dart 文件
  final appRouterFile = File('lib/core/router/app_router.dart');
  if (!appRouterFile.existsSync()) {
    _logger.info('❌ 错误: 找不到 app_router.dart 文件');
    exit(1);
  }

  // 备份原文件
  final backupFile = File('lib/core/router/app_router.dart.bak');
  appRouterFile.copySync(backupFile.path);
  _logger.info('💾 已备份原文件到 app_router.dart.bak');

  // 写入新内容
  appRouterFile.writeAsStringSync(output);
  _logger.info('✅ 已更新 app_router.dart 文件');

  // 运行代码格式化
  _logger.info('\n🎨 正在格式化代码...');
  Process.runSync('dart', ['format', 'lib/core/router/app_router.dart']);
  _logger.info('✅ 代码格式化完成\n');

  _logger.info('🎉 路由常量生成完成！');
  _logger.info('💡 提示: 运行以下命令重新生成路由代码:');
  _logger.info(
    '   flutter pub run build_runner build --delete-conflicting-outputs',
  );
}

/// 生成 AppRoutes 类代码
String _generateAppRoutesClass(List<RoutePageInfo> pages) {
  final buffer = StringBuffer();

  buffer.writeln("import 'package:auto_route/auto_route.dart';");

  // 按模块分组生成导入
  final imports = <String>{};
  for (final page in pages) {
    imports.add(page.importPath);
  }

  for (final import in imports.toList()..sort()) {
    buffer.writeln("import '$import';");
  }

  buffer.writeln('''
part 'app_router.gr.dart';

/// 应用路由常量类
/// 集中管理所有路由配置，便于维护和扩展
/// ⚠️  注意: 此文件由代码生成器自动生成，请勿手动修改
/// 如需修改路由配置，请运行: dart tool/generate_routes_constants.dart
class AppRoutes {
  // 私有构造函数，防止实例化
  AppRoutes._();
''');

  // 生成各个路由常量
  for (final page in pages) {
    // 生成更好的变量名：移除 Page/View 后缀，保持首字母大写
    final varName = _generateVariableName(page.className);
    // MainPage 设置为初始路由
    final isInitial = page.className == 'MainPage' ? 'initial: true,' : '';

    buffer.writeln('''
  /// ${_generateComment(page.className, page.module)}
  static final $varName = AutoRoute(
    page: ${page.routeName}.page,
    path: '${page.routePath}',
    $isInitial
  );
''');
  }

  // 生成 all 列表
  buffer.writeln('  /// 所有路由的集合');
  buffer.writeln('  /// 在 AppRouter 中直接使用此集合来简化配置');
  buffer.writeln('  static final List<AutoRoute> all = [');

  for (final page in pages) {
    final varName = _generateVariableName(page.className);
    buffer.writeln('    $varName,');
  }

  buffer.writeln('  ];');
  buffer.writeln('}');
  buffer.writeln('');
  buffer.writeln('@AutoRouterConfig()');
  buffer.writeln('class AppRouter extends RootStackRouter {');
  buffer.writeln('  @override');
  buffer.writeln('  List<AutoRoute> get routes => AppRoutes.all;');
  buffer.writeln('}');

  return buffer.toString();
}

/// 将类名转换为路由名称
String _toRouteName(String className) {
  // 移除 Page 后缀
  var name = className.replaceAll('Page', '');
  // 移除 View 后缀
  name = name.replaceAll('View', '');
  // 添加 Route 后缀
  return '${name}Route';
}

/// 生成路由路径
String _generateRoutePath(String module, String className) {
  // InterpretView 使用 /interpret 路径
  if (className == 'InterpretView' || className == 'MainPage') return '/';

  // 其他页面使用模块名
  final pageName = className
      .replaceAll('Page', '')
      .replaceAll('View', '')
      .toLowerCase();
  return '/$module/$pageName';
}

/// 生成变量名
String _generateVariableName(String className) {
  // 移除 Page 或 View 后缀
  var name = className.replaceAll('Page', '').replaceAll('View', '');

  // 如果是单个单词，首字母小写
  if (name.length <= 1) return name.toLowerCase();

  // 首字母小写，其余保持原样（处理驼峰命名）
  return name[0].toLowerCase() + name.substring(1);
}

/// 生成注释
String _generateComment(String className, String module) {
  final comment = className.replaceAll('Page', '页面').replaceAll('View', '视图');
  return '$comment ($module 模块)';
}

/// 获取导入路径
String _getImportPath(String filePath) {
  final relativePath = p.relative(filePath, from: 'lib');
  final importPath = relativePath.replaceAll('\\', '/');
  return 'package:aif2f/$importPath';
}

/// 路由页面信息
class RoutePageInfo {
  final String className;
  final String routeName;
  final String routePath;
  final String module;
  final String importPath;

  RoutePageInfo({
    required this.className,
    required this.routeName,
    required this.routePath,
    required this.module,
    required this.importPath,
  });

  @override
  String toString() {
    return '$className -> $routeName ($routePath)';
  }
}

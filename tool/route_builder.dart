import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// 主路由生成器 - 用于生成所有路由的导入代码
class MainRouteGenerator implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    // 定义路由文件的glob模式
    final routeFilesGlob = Glob('lib/**/routes/*_routes.dart');

    // 查找所有路由文件
    final routeFiles = await buildStep.findAssets(routeFilesGlob).toList();

    // 生成路由导入代码
    final imports = <String>[];

    for (final assetId in routeFiles) {
      // 获取模块名称
      final pathSegments = assetId.pathSegments;
      final moduleIndex = pathSegments.indexOf('lib') + 1;
      if (moduleIndex < pathSegments.length) {
        final moduleName = pathSegments[moduleIndex];

        // 生成导入语句
        final importPath = '../../$moduleName/routes/${moduleName}_routes.dart';
        imports.add(importPath);
      }
    }

    // 生成导入文件内容
    final content =
        '''
// 自动生成的路由导入文件
// 请勿手动修改
// 该文件由代码生成器自动生成，包含所有模块的路由文件导入

${imports.map((import) => "import '$import';").join('\n')}
''';

    // 写入生成的文件
    final outputAsset = AssetId(
      buildStep.inputId.package,
      'lib/core/routes/generated_route_imports.dart',
    );
    await buildStep.writeAsString(outputAsset, content);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['core/routes/generated_route_imports.dart'],
  };
}

/// 路由构建器 - 配置所有路由相关的构建器
Builder routeBuilder(BuilderOptions options) => MainRouteGenerator();

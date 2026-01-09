import 'package:auto_route/auto_route.dart';
import 'package:aif2f/home/home_page.dart';
import 'package:aif2f/interpret/view/interpret_view.dart';
import 'package:aif2f/user/view/profile_page.dart';
import 'package:aif2f/user/view/settings_page.dart';
import 'package:aif2f/user/view/about_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    // 主页/根页面
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
    ),
    // 传译页面
    AutoRoute(page: InterpretRoute.page, path: '/interpret'),
    // 个人信息页面
    AutoRoute(page: ProfileRoute.page, path: '/profile'),
    // 设置页面
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    // 关于页面
    AutoRoute(page: AboutRoute.page, path: '/about'),
  ];
}

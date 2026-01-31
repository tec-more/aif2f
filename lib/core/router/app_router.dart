import 'package:auto_route/auto_route.dart';
import 'package:aif2f/interpret/view/interpret_view.dart';
import 'package:aif2f/scene/view/activity_scene_page.dart';
import 'package:aif2f/scene/view/education_scene_page.dart';
import 'package:aif2f/scene/view/interview_scene_page.dart';
import 'package:aif2f/scene/view/meeting_scene_page.dart';
import 'package:aif2f/scene/view/presentation_scene_page.dart';
import 'package:aif2f/user/view/about_page.dart';
import 'package:aif2f/user/view/profile_page.dart';
import 'package:aif2f/user/view/settings_page.dart';
part 'app_router.gr.dart';

/// 应用路由常量类
/// 集中管理所有路由配置，便于维护和扩展
/// ⚠️  注意: 此文件由代码生成器自动生成，请勿手动修改
/// 如需修改路由配置，请运行: dart tool/generate_routes_constants.dart
class AppRoutes {
  // 私有构造函数，防止实例化
  AppRoutes._();

  /// Interpret视图 (interpret 模块)
  static final interpret = AutoRoute(page: InterpretRoute.page, path: '/');

  /// ActivityScene页面 (scene 模块)
  static final activityScene = AutoRoute(
    page: ActivitySceneRoute.page,
    path: '/scene/activityscene',
  );

  /// EducationScene页面 (scene 模块)
  static final educationScene = AutoRoute(
    page: EducationSceneRoute.page,
    path: '/scene/educationscene',
  );

  /// MeetingScene页面 (scene 模块)
  static final meetingScene = AutoRoute(
    page: MeetingSceneRoute.page,
    path: '/scene/meetingscene',
  );

  /// PresentationScene页面 (scene 模块)
  static final presentationScene = AutoRoute(
    page: PresentationSceneRoute.page,
    path: '/scene/presentationscene',
  );

  /// InterviewScene页面 (scene 模块)
  static final interviewScene = AutoRoute(
    page: InterviewSceneRoute.page,
    path: '/scene/interviewscene',
  );

  /// About页面 (user 模块)
  static final about = AutoRoute(page: AboutRoute.page, path: '/user/about');

  /// Profile页面 (user 模块)
  static final profile = AutoRoute(
    page: ProfileRoute.page,
    path: '/user/profile',
  );

  /// Settings页面 (user 模块)
  static final settings = AutoRoute(
    page: SettingsRoute.page,
    path: '/user/settings',
  );

  /// 所有路由的集合
  /// 在 AppRouter 中直接使用此集合来简化配置
  /// 🔒 已注释除传译功能以外的所有路由，仅保留传译功能
  static final List<AutoRoute> all = [
    interpret,
    // // ========== 场景页面路由（已临时注释）==========
    // activityScene,
    // educationScene,
    // interviewScene,
    // meetingScene,
    // presentationScene,
    // // ========== 用户页面路由（已临时注释）==========
    // about,
    // profile,
    // settings,
  ];
}

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => AppRoutes.all;
}

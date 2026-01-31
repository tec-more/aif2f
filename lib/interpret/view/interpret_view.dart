import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/components/icon/icon_text.dart';
import 'package:country_icons/country_icons.dart';
// // 🔒 已临时注释未使用的导入
// import 'package:aif2f/scene/view/scene_menu.dart';
// import 'package:aif2f/user/view/user_menu.dart';
// import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/interpret/viewmodel/interpret_view_model.dart';
import 'package:aif2f/core/config/app_config.dart';
import 'package:aif2f/interpret/widgets/auto_scroll_translation_view.dart';
import 'package:aif2f/interpret/widgets/member_drawer.dart';

/// 传译场景页面
@RoutePage(name: 'InterpretRoute')
class InterpretView extends ConsumerWidget {
  const InterpretView({super.key});

  // 语言列表（根据讯飞API限制，目前只支持中英文互译）
  static const List<String> _languages = [
    '中文',
    '英语',
  ];

  // 语言简称映射
  static const Map<String, String> _languageCodes = {
    '英语': 'EN',
    '中文': 'ZH',
    '日语': 'JA',
    '韩语': 'KO',
    '法语': 'FR',
    '德语': 'DE',
    '西班牙语': 'ES',
    '俄语': 'RU',
  };

  // 语言到国旗图标的映射（使用country_icons包）
  static final Map<String, String> _languageFlags = {
    '英语': 'us',
    '中文': 'cn',
    '日语': 'jp',
    '韩语': 'kr',
    '法语': 'fr',
    '德语': 'de',
    '西班牙语': 'es',
    '俄语': 'ru',
  };

  // 语言选择器的全局键
  static final GlobalKey _languageOneSelectorKey = GlobalKey();
  static final GlobalKey _languageTwoSelectorKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听传译状态
    final state = ref.watch(interpretViewModelProvider);

    // 初始化翻译服务 - 仅当未连接时初始化
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: '菜单',
          ),
        ),
        title: Text(
          'AI传译',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // // 🔒 已临时注释场景菜单和用户菜单
          // SceneMenu(selectedScene: SceneType.interpretation),
          // const UserMenu(),
        ],
      ),
      drawer: const MemberDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎标题
              Row(
                children: [
                  // 左侧文本 - 占用剩余空间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '欢迎使用AI传译',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                    ? 20
                                    : 24,
                              ),
                        ),
                        SizedBox(height: 4), // 添加间距
                        Text(
                          '轻松实现多语言翻译',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                    ? 12
                                    : 14,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // SizedBox(width: 16), // 左右间距
                  // 右侧按钮 - 自适应宽度
                  Row(
                    mainAxisSize: MainAxisSize.min, // 重要：Row只占据内容所需空间
                    children: [
                      if (Platform.isWindows) _systemSoundButton(context, ref),
                      if (Platform.isWindows) SizedBox(width: 16),
                      _buildRecordButton(context, ref),
                    ],
                  ),
                ],
              ),

              SizedBox(
                height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              ),
              Row(
                children: [
                  if (ref.watch(interpretViewModelProvider).panelNumber == 1)
                    Expanded(child: _buildOneColumnLayout(context, ref)),
                  if (ref.watch(interpretViewModelProvider).panelNumber == 1)
                    SizedBox(width: 12),
                  Expanded(child: _buildTwoColumnLayout(context, ref)),
                ],
              ),

              // debugPrint('panelNumber: ${ref.watch(interpretViewModelProvider).panelNumber}');
            ],
          ),
        ),
      ),
    );
  }

  /// 语言选择器
  Widget _buildLanguageSelector(
    WidgetRef ref,
    BuildContext context, [
    int type = 1,
  ]) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 150,
        child: MouseRegion(
          key: type == 1 ? _languageOneSelectorKey : _languageTwoSelectorKey,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => type == 1
                ? _showOneLanguageSelector(context, ref)
                : _showTwoLanguageSelector(context, ref),
            child: Builder(
              builder: (buttonContext) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(
                      buttonContext,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(
                    buttonContext,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // 确保AnimatedContainer也受到宽度限制
                constraints: BoxConstraints(maxWidth: 100),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 源语言 - 移除Expanded，使用固定宽度
                    SizedBox(
                      width: 40,
                      child: Row(
                        children: [
                          Image.asset(
                            'icons/flags/png100px/${_languageFlags[type == 1 ? ref.watch(interpretViewModelProvider).sourceOneLanguage : ref.watch(interpretViewModelProvider).sourceTwoLanguage]}.png',
                            package: 'country_icons',
                            width: 16,
                            height: 12,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type == 1
                                ? _languageCodes[ref
                                          .watch(interpretViewModelProvider)
                                          .sourceOneLanguage] ??
                                      ref
                                          .watch(interpretViewModelProvider)
                                          .sourceOneLanguage
                                : _languageCodes[ref
                                          .watch(interpretViewModelProvider)
                                          .sourceTwoLanguage] ??
                                      ref
                                          .watch(interpretViewModelProvider)
                                          .sourceTwoLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                buttonContext,
                              ).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 翻译方向箭头 - 减小内边距
                    Container(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Theme.of(buttonContext).colorScheme.primary,
                        size: 14,
                      ),
                    ),

                    // 目标语言 - 移除Expanded，使用固定宽度
                    SizedBox(
                      width: 40,
                      child: Row(
                        children: [
                          Image.asset(
                            type == 1
                                ? 'icons/flags/png100px/${_languageFlags[ref.watch(interpretViewModelProvider).targetOneLanguage]}.png'
                                : 'icons/flags/png100px/${_languageFlags[ref.watch(interpretViewModelProvider).targetTwoLanguage]}.png',
                            package: 'country_icons',
                            width: 16,
                            height: 12,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type == 1
                                ? _languageCodes[ref
                                          .watch(interpretViewModelProvider)
                                          .targetOneLanguage] ??
                                      ref
                                          .watch(interpretViewModelProvider)
                                          .targetOneLanguage
                                : _languageCodes[ref
                                          .watch(interpretViewModelProvider)
                                          .targetTwoLanguage] ??
                                      ref
                                          .watch(interpretViewModelProvider)
                                          .targetTwoLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                buttonContext,
                              ).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 布局弹出窗口
  Widget _buildLayoutPopupWindow(
    BuildContext context,
    WidgetRef ref, [
    int type = 1,
  ]) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.more_horiz_rounded, size: 24),
          onPressed: () {
            // 使用showMenu实现弹出框，确保它始终跟随按钮移动
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;

            // 获取按钮的位置信息
            final buttonPosition = button.localToGlobal(
              Offset.zero,
              ancestor: overlay,
            );

            // 计算弹出框位置：从按钮下方弹出
            // 菜单的右边缘对齐按钮的右边缘
            // 菜单的上边缘对齐按钮的下边缘
            final position =
                RelativeRect.fromRect(
                  // 按钮的矩形区域
                  Rect.fromLTWH(
                    buttonPosition.dx,
                    buttonPosition.dy,
                    button.size.width,
                    button.size.height,
                  ),
                  // 叠加层的矩形区域
                  Offset.zero & overlay.size,
                ).shift(
                  Offset(
                    button.size.width, // 向左偏移，使菜单右边缘对齐按钮右边缘
                    button.size.height, // 向下偏移，使菜单在按钮下方
                  ),
                );

            showMenu(
              context: context,
              position: position,
              items: [
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 280, // 足够的宽度，避免溢出
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 字号部分 - 标题和按钮同一行
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '字号',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      // 减小字号
                                      final state = ref.watch(
                                        interpretViewModelProvider,
                                      );
                                      final fontSize = type == 1
                                          ? state.onefontSize
                                          : state.twofontSize;
                                      if (fontSize > 10) {
                                        type == 1
                                            ? ref
                                                  .read(
                                                    interpretViewModelProvider
                                                        .notifier,
                                                  )
                                                  .setOnefontSize(fontSize - 1)
                                            : ref
                                                  .read(
                                                    interpretViewModelProvider
                                                        .notifier,
                                                  )
                                                  .setTwofontSize(fontSize - 1);
                                      }
                                    },
                                    icon: const Text(
                                      'A-',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      // 增大字号
                                      final state = ref.watch(
                                        interpretViewModelProvider,
                                      );
                                      final fontSize = type == 1
                                          ? state.onefontSize
                                          : state.twofontSize;
                                      if (fontSize < 24) {
                                        type == 1
                                            ? ref
                                                  .read(
                                                    interpretViewModelProvider
                                                        .notifier,
                                                  )
                                                  .setOnefontSize(fontSize + 1)
                                            : ref
                                                  .read(
                                                    interpretViewModelProvider
                                                        .notifier,
                                                  )
                                                  .setTwofontSize(fontSize + 1);
                                      }
                                    },
                                    icon: const Text(
                                      'A+',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 面板部分 - 标题和按钮同一行
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '面板',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      // 单面板
                                      ref
                                          .read(
                                            interpretViewModelProvider.notifier,
                                          )
                                          .setPanelNumber(2);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.crop_portrait_rounded,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  if (Platform.isWindows)
                                    IconButton(
                                      onPressed: () {
                                        // 双面板
                                        ref
                                            .read(
                                              interpretViewModelProvider
                                                  .notifier,
                                            )
                                            .setPanelNumber(1);
                                        Navigator.pop(context);
                                      },
                                      icon: const TwoPanelsIcon(),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      constraints: const BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 文本部分 - 标题和按钮同一行
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '文本',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      // 文本布局1 - 单行文本
                                      type == 1
                                          ? ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setOneContentTypes('o2o')
                                          : ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setTwoContentTypes('o2o');
                                    },
                                    icon: const TextLayout1Icon(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      // 文本布局2 - 两行文本
                                      type == 1
                                          ? ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setOneContentTypes('s2s')
                                          : ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setTwoContentTypes('s2s');
                                    },
                                    icon: const TextLayout2Icon(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      // 文本布局3 - 三行文本
                                      type == 1
                                          ? ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setOneContentTypes('o2s')
                                          : ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setTwoContentTypes('o2s');
                                    },
                                    icon: const TextLayout3Icon(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      // 文本布局4 - 列表视图
                                      type == 1
                                          ? ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setOneContentTypes('t2t')
                                          : ref
                                                .read(
                                                  interpretViewModelProvider
                                                      .notifier,
                                                )
                                                .setTwoContentTypes('t2t');
                                    },
                                    icon: const TextLayout4Icon(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              elevation: 8,
            );
          },
          color: Theme.of(context).colorScheme.primary,
          tooltip: '设置',
        ),
      ),
    );
  }

  /// 系统声音按钮
  Widget _systemSoundButton(BuildContext context, WidgetRef ref) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Builder(
        builder: (context) => IconButton(
          icon: ref.watch(interpretViewModelProvider).isSystemSoundEnabled
              ? const Icon(Icons.volume_up_outlined, size: 24)
              : const Icon(Icons.volume_off_outlined, size: 24),
          onPressed: () {
            ref.read(interpretViewModelProvider.notifier).toggleSystemSound();
            // 开启系统声音时候，默认使用2栏
            if (ref.watch(interpretViewModelProvider).isSystemSoundEnabled) {
              ref.read(interpretViewModelProvider.notifier).setPanelNumber(1);
              debugPrint('系统声音按钮点击开始');
              ref.read(interpretViewModelProvider.notifier).startSystemSound();
            } else {
              ref.read(interpretViewModelProvider.notifier).setPanelNumber(2);
              debugPrint('系统声音按钮点击结束');
              ref.read(interpretViewModelProvider.notifier).stopSystemSound();
            }
          },
          tooltip: '获取系统声音',
        ),
      ),
    );
  }

  /// TTS 播报按钮
  /// [panel] 栏目：1 = 一栏, 2 = 二栏
  Widget _ttsButton(BuildContext context, WidgetRef ref, {required int panel}) {
    final state = ref.watch(interpretViewModelProvider);
    final isEnabled = panel == 1
        ? state.isOneTtsEnabled
        : state.isTwoTtsEnabled;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Builder(
        builder: (context) => IconButton(
          icon: isEnabled
              ? const Icon(Icons.record_voice_over, size: 22)
              : const Icon(Icons.voice_over_off, size: 22),
          color: isEnabled ? Theme.of(context).colorScheme.primary : null,
          onPressed: () {
            if (panel == 1) {
              ref.read(interpretViewModelProvider.notifier).toggleOneTts();
            } else {
              ref.read(interpretViewModelProvider.notifier).toggleTwoTts();
            }
          },
          tooltip: ' ${isEnabled ? "停止播报" : "开始播报"}',
        ),
      ),
    );
  }

  /// 构建录音按钮
  Widget _buildRecordButton(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final state = ref.watch(interpretViewModelProvider);
    final isRecording = state.isProcessing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(interpretViewModelProvider.notifier).toggleRecording();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMobile ? 80 : 200,
          height: isMobile ? 48 : 44,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRecording
                  ? [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
            boxShadow: [
              BoxShadow(
                color: isRecording
                    ? Colors.red.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRecording)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              if (isMobile) const SizedBox(width: 8),
              if (isMobile)
                Text(
                  isRecording ? '录音中...' : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 语言输入输出说明
  ///
  /// o2o 只显示源语言，s2s 只显示目标语言，o2s 显示源语言和目标语言，t2t 源语言和目标语言分离
  /// 开启系统声音时候，默认使用2栏
  ///
  /// 构建O2O文本框/输入卡片
  Widget _buildO2OTextField(
    BuildContext context,
    WidgetRef ref, [
    int type = 1,
  ]) {
    final state = ref.watch(interpretViewModelProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
            (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.6),
        child: Column(
          children: [
            // 源语言输入区
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 12 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                                text: type == 1
                                    ? state.inputOneText
                                    : state.inputTwoText,
                              )
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: type == 1
                                      ? state.inputOneText.length
                                      : state.inputTwoText.length,
                                ),
                              ),
                        onChanged: (text) {
                          ref
                              .read(interpretViewModelProvider.notifier)
                              .setInputText(text, type);
                        },
                        onSubmitted: (text) {
                          ref
                              .read(interpretViewModelProvider.notifier)
                              .translateText(text, type);
                        },
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '源语言',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: type == 1
                                ? state.onefontSize
                                : state.twofontSize,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: type == 1
                              ? state.onefontSize
                              : state.twofontSize,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建S2S文本框/输入卡片（只显示目标语言）
  Widget _buildS2STextField(
    BuildContext context,
    WidgetRef ref, [
    int type = 1,
  ]) {
    final state = ref.watch(interpretViewModelProvider);
    final translatedText = type == 1
        ? state.translatedOneText
        : state.translatedTwoText;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
            (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.6),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 12 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: translatedText)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: translatedText.length),
                    ),
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  readOnly: true, // 翻译结果只读
                  decoration: InputDecoration(
                    hintText: '目标语言',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontSize: type == 1
                          ? state.onefontSize
                          : state.twofontSize,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: type == 1
                        ? state.onefontSize
                        : state.twofontSize,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建O2S文本框/输入卡片（原文和译文交替显示）
  Widget _buildO2STextField(
    BuildContext context,
    WidgetRef ref, [
    int type = 1,
  ]) {
    final state = ref.watch(interpretViewModelProvider);
    final inputText = type == 1 ? state.inputOneText : state.inputTwoText;
    final translatedText = type == 1
        ? state.translatedOneText
        : state.translatedTwoText;
    final fontSize = type == 1 ? state.onefontSize : state.twofontSize;

    // 使用特殊分隔符分割句子
    final List<String> inputSentences = inputText.isEmpty
        ? []
        : inputText
              .split(AppConfig.sentenceSeparator)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
    final List<String> translatedSentences = translatedText.isEmpty
        ? []
        : translatedText
              .split(AppConfig.sentenceSeparator)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

    // 创建所有行的列表
    final List<Widget> allLines = [];

    // 计算最大句子对数量
    final maxPairs = inputSentences.length > translatedSentences.length
        ? inputSentences.length
        : translatedSentences.length;

    for (int i = 0; i < maxPairs; i++) {
      // 奇数行：显示原文
      if (i < inputSentences.length) {
        allLines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                inputSentences[i],
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black54,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }

      // 偶数行：显示译文
      if (i < translatedSentences.length) {
        allLines.add(
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                translatedSentences[i],
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
            (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.6),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 12 : 24,
          ),
          child: AutoScrollTranslationView(
            sourceSentences: inputSentences,
            targetSentences: translatedSentences,
            fontSize: fontSize,
            initialText: type == 1 ? state.inputOneText : state.inputTwoText,
            onChanged: (text) {
              ref.read(interpretViewModelProvider.notifier).setInputText(text, type);
            },
            onSubmitted: (text) {
              ref.read(interpretViewModelProvider.notifier).translateText(text, type);
            },
          ),
        ),
      ),
    );
  }

  /// 构建F2F文本输入/输出卡片（上下分栏）
  Widget _buildF2fTextField(
    BuildContext context,
    WidgetRef ref, [
    int type = 1,
  ]) {
    final state = ref.watch(interpretViewModelProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height *
            (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.6),
        child: Column(
          children: [
            // 源语言输入区
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 12 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                                text: type == 1
                                    ? state.inputOneText
                                    : state.inputTwoText,
                              )
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: type == 1
                                      ? state.inputOneText.length
                                      : state.inputTwoText.length,
                                ),
                              ),
                        onChanged: (text) {
                          ref
                              .read(interpretViewModelProvider.notifier)
                              .setInputText(text, type);
                        },
                        onSubmitted: (text) {
                          ref
                              .read(interpretViewModelProvider.notifier)
                              .translateText(text, type);
                        },
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '源语言',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: type == 1
                                ? state.onefontSize
                                : state.twofontSize,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: type == 1
                              ? state.onefontSize
                              : state.twofontSize,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 分隔线
            Divider(
              height: 1,
              thickness: 1,
              indent: MediaQuery.of(context).size.width < 600 ? 12 : 24,
              endIndent: MediaQuery.of(context).size.width < 600 ? 12 : 24,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            // 目标语言输出区
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 12 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                                text: type == 1
                                    ? state.translatedOneText
                                    : state.translatedTwoText,
                              )
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: type == 1
                                      ? state.translatedOneText.length
                                      : state.translatedTwoText.length,
                                ),
                              ),
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '目标语言',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600
                                ? 14
                                : 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600
                              ? 12
                              : 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 一栏文本框
  Widget _buildOneColumnLayout(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);
    // debugPrint('panelNumber: ${state.panelNumber}');
    return Column(
      children: [
        // 语言选择卡片
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 8 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLanguageSelector(ref, context, 1),
                const SizedBox(width: 16),
                // _buildTranslateButton(context, ref),
                // const SizedBox(width: 16),
                _ttsButton(context, ref, panel: 1), // 一栏 TTS 播报按钮
                const SizedBox(width: 8),
                Expanded(child: _buildLayoutPopupWindow(context, ref, 1)),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
        // 文本输入/输出卡片
        if (state.oneContentTypes == 'o2o') _buildO2OTextField(context, ref, 1),
        if (state.oneContentTypes == 's2s') _buildS2STextField(context, ref, 1),
        if (state.oneContentTypes == 'o2s') _buildO2STextField(context, ref, 1),
        if (state.oneContentTypes == 't2t') _buildF2fTextField(context, ref, 1),
      ],
    );
  }

  /// 二栏文本框
  Widget _buildTwoColumnLayout(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);
    // debugPrint('panelNumber: ${state.panelNumber}');
    return Column(
      children: [
        // 语言选择卡片
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 8 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLanguageSelector(ref, context, 2),
                const SizedBox(width: 16),
                // _buildTranslateButton(context, ref),
                // const SizedBox(width: 16),
                _ttsButton(context, ref, panel: 2), // 二栏 TTS 播报按钮
                const SizedBox(width: 8),
                Expanded(child: _buildLayoutPopupWindow(context, ref, 2)),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
        // 文本输入/输出卡片
        if (state.twoContentTypes == 'o2o') _buildO2OTextField(context, ref, 2),
        if (state.twoContentTypes == 's2s') _buildS2STextField(context, ref, 2),
        if (state.twoContentTypes == 'o2s') _buildO2STextField(context, ref, 2),
        if (state.twoContentTypes == 't2t') _buildF2fTextField(context, ref, 2),
      ],
    );
  }

  /// 显示语言选择器
  void _showOneLanguageSelector(BuildContext context, WidgetRef ref) {
    // 获取语言选择器的位置
    final renderBox =
        _languageOneSelectorKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderBox,
    );

    // 创建状态变量
    String sourceOneLanguage = ref
        .watch(interpretViewModelProvider)
        .sourceOneLanguage;
    String targetOneLanguage = ref
        .watch(interpretViewModelProvider)
        .targetOneLanguage;

    // 使用late关键字延迟初始化overlayEntry
    late final OverlayEntry overlayEntry;

    // 创建OverlayEntry
    overlayEntry = OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        // 点击外部关闭弹出框
        onTap: () {
          overlayEntry.remove();
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy + renderBox.size.height + 8,
                child: GestureDetector(
                  // 防止点击内部关闭弹出框
                  onTap: () {
                    // 阻止事件冒泡
                  },
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 290, //增加宽度以确保良好显示
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题
                          const Text(
                            '语言选择',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 左右两栏布局
                          Row(
                            children: [
                              // 源语言选择（左侧）
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '源语言',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _languages
                                          .where(
                                            (lang) => lang != targetOneLanguage,
                                          )
                                          .map(
                                            (lang) => ChoiceChip(
                                              label: Container(
                                                width: 60, // 固定选项宽度
                                                child: Row(
                                                  children: [
                                                    // 使用country_icons包中的正确路径格式
                                                    Image.asset(
                                                      'icons/flags/png100px/${_languageFlags[lang]}.png',
                                                      package: 'country_icons',
                                                      width: 16,
                                                      height: 12,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _languageCodes[lang] ??
                                                          lang,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              selected:
                                                  sourceOneLanguage == lang,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  // 更新ViewModel中的状态
                                                  ref
                                                      .read(
                                                        interpretViewModelProvider
                                                            .notifier,
                                                      )
                                                      .setLanguages(
                                                        lang,
                                                        targetOneLanguage,
                                                        1,
                                                      );
                                                  // 重新构建Overlay以更新UI，保持弹出层显示
                                                  overlayEntry.remove();
                                                  _showOneLanguageSelector(
                                                    context,
                                                    ref,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),

                              // 交换语言按钮（中间）
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // 调用ViewModel的交换语言方法
                                        ref
                                            .read(
                                              interpretViewModelProvider
                                                  .notifier,
                                            )
                                            .swapLanguages(1);
                                        // 重新构建Overlay以更新UI，保持弹出层显示
                                        overlayEntry.remove();
                                        _showOneLanguageSelector(context, ref);
                                      },
                                      icon: const Icon(Icons.swap_horiz),
                                      tooltip: '交换语言',
                                    ),
                                  ],
                                ),
                              ),

                              // 目标语言选择（右侧）
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '目标语言',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _languages
                                          .where(
                                            (lang) => lang != sourceOneLanguage,
                                          )
                                          .map(
                                            (lang) => ChoiceChip(
                                              label: Container(
                                                width: 60, // 固定选项宽度
                                                child: Row(
                                                  children: [
                                                    // 使用country_icons包中的正确路径格式
                                                    Image.asset(
                                                      'icons/flags/png100px/${_languageFlags[lang]}.png',
                                                      package: 'country_icons',
                                                      width: 16,
                                                      height: 12,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _languageCodes[lang] ??
                                                          lang,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              selected:
                                                  targetOneLanguage == lang,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  // 更新ViewModel中的状态
                                                  ref
                                                      .read(
                                                        interpretViewModelProvider
                                                            .notifier,
                                                      )
                                                      .setLanguages(
                                                        sourceOneLanguage,
                                                        lang,
                                                        1,
                                                      );
                                                  // 重新构建Overlay以更新UI，保持弹出层显示
                                                  overlayEntry.remove();
                                                  _showOneLanguageSelector(
                                                    context,
                                                    ref,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 插入OverlayEntry
    overlay.insert(overlayEntry);
  }

  void _showTwoLanguageSelector(BuildContext context, WidgetRef ref) {
    // 获取语言选择器的位置
    final renderBox =
        _languageTwoSelectorKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderBox,
    );

    // 创建状态变量
    String sourceTwoLanguage = ref
        .watch(interpretViewModelProvider)
        .sourceTwoLanguage;
    String targetTwoLanguage = ref
        .watch(interpretViewModelProvider)
        .targetTwoLanguage;

    // 使用late关键字延迟初始化overlayEntry
    late final OverlayEntry overlayEntry;

    // 创建OverlayEntry
    overlayEntry = OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        // 点击外部关闭弹出框
        onTap: () {
          overlayEntry.remove();
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy + renderBox.size.height + 8,
                child: GestureDetector(
                  // 防止点击内部关闭弹出框
                  onTap: () {
                    // 阻止事件冒泡
                  },
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 290, //增加宽度以确保良好显示
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题
                          const Text(
                            '语言选择',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 左右两栏布局
                          Row(
                            children: [
                              // 源语言选择（左侧）
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '源语言',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _languages
                                          .where(
                                            (lang) => lang != targetTwoLanguage,
                                          )
                                          .map(
                                            (lang) => ChoiceChip(
                                              label: Container(
                                                width: 60, // 固定选项宽度
                                                child: Row(
                                                  children: [
                                                    // 使用country_icons包中的正确路径格式
                                                    Image.asset(
                                                      'icons/flags/png100px/${_languageFlags[lang]}.png',
                                                      package: 'country_icons',
                                                      width: 16,
                                                      height: 12,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _languageCodes[lang] ??
                                                          lang,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              selected:
                                                  sourceTwoLanguage == lang,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  // 更新ViewModel中的状态
                                                  ref
                                                      .read(
                                                        interpretViewModelProvider
                                                            .notifier,
                                                      )
                                                      .setLanguages(
                                                        lang,
                                                        targetTwoLanguage,
                                                        2,
                                                      );
                                                  // 重新构建Overlay以更新UI，保持弹出层显示
                                                  overlayEntry.remove();
                                                  _showTwoLanguageSelector(
                                                    context,
                                                    ref,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),

                              // 交换语言按钮（中间）
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // 调用ViewModel的交换语言方法
                                        ref
                                            .read(
                                              interpretViewModelProvider
                                                  .notifier,
                                            )
                                            .swapLanguages(2);
                                        // 重新构建Overlay以更新UI，保持弹出层显示
                                        overlayEntry.remove();
                                        _showTwoLanguageSelector(context, ref);
                                      },
                                      icon: const Icon(Icons.swap_horiz),
                                      tooltip: '交换语言',
                                    ),
                                  ],
                                ),
                              ),

                              // 目标语言选择（右侧）
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '目标语言',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _languages
                                          .where(
                                            (lang) => lang != sourceTwoLanguage,
                                          )
                                          .map(
                                            (lang) => ChoiceChip(
                                              label: Container(
                                                width: 60, // 固定选项宽度
                                                child: Row(
                                                  children: [
                                                    // 使用country_icons包中的正确路径格式
                                                    Image.asset(
                                                      'icons/flags/png100px/${_languageFlags[lang]}.png',
                                                      package: 'country_icons',
                                                      width: 16,
                                                      height: 12,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _languageCodes[lang] ??
                                                          lang,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              selected:
                                                  targetTwoLanguage == lang,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  // 更新ViewModel中的状态
                                                  ref
                                                      .read(
                                                        interpretViewModelProvider
                                                            .notifier,
                                                      )
                                                      .setLanguages(
                                                        sourceTwoLanguage,
                                                        lang,
                                                        2,
                                                      );
                                                  // 重新构建Overlay以更新UI，保持弹出层显示
                                                  overlayEntry.remove();
                                                  _showTwoLanguageSelector(
                                                    context,
                                                    ref,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 插入OverlayEntry
    overlay.insert(overlayEntry);
  }
}

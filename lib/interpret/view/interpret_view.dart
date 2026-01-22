import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/components/icon/icon_text.dart';
import 'package:country_icons/country_icons.dart';
import 'package:aif2f/scene/view/scene_menu.dart';
import 'package:aif2f/user/view/user_menu.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/interpret/viewmodel/interpret_view_model.dart';

/// 传译场景页面
@RoutePage(name: 'InterpretRoute')
class InterpretView extends ConsumerWidget {
  const InterpretView({super.key});

  // 语言列表
  static const List<String> _languages = [
    '英语',
    '中文',
    '日语',
    '韩语',
    '法语',
    '德语',
    '西班牙语',
    '俄语',
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
    if (!state.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interpretViewModelProvider.notifier).initialize();
      });
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'AI传译',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          SceneMenu(selectedScene: SceneType.interpretation),
          const UserMenu(),
        ],
      ),
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
                  Expanded(child: _buildOneColumnLayout(context, ref)),
                  SizedBox(width: 12),
                  if (ref.watch(interpretViewModelProvider).panelNumber == 2)
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
          },
          color: Theme.of(context).colorScheme.primary,
          tooltip: '翻译系统声音',
        ),
      ),
    );
  }

  /// 布局弹出窗口
  Widget _buildLayoutPopupWindow(BuildContext context, WidgetRef ref) {
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
                                          .setPanelNumber(1);
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
                                            .setPanelNumber(2);
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

  /// 一栏文本框
  Widget _buildOneColumnLayout(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);
    debugPrint('panelNumber: ${state.panelNumber}');
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
                Expanded(child: _buildLayoutPopupWindow(context, ref)),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
        // 文本输入/输出卡片
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.5),
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
                                TextEditingController(text: state.inputText)
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: state.inputText.length,
                                    ),
                                  ),
                            onChanged: (text) {
                              ref
                                  .read(interpretViewModelProvider.notifier)
                                  .setInputText(text);
                            },
                            onSubmitted: (text) {
                              ref
                                  .read(interpretViewModelProvider.notifier)
                                  .translateText(text);
                            },
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: '源语言',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
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
                                    text: state.translatedText,
                                  )
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: state.translatedText.length,
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
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
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
        ),
      ],
    );
  }

  /// 二栏文本框
  Widget _buildTwoColumnLayout(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);
    debugPrint('panelNumber: ${state.panelNumber}');
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
                Expanded(child: _buildLayoutPopupWindow(context, ref)),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),
        // 文本输入/输出卡片
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.5),
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
                                TextEditingController(text: state.inputText)
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: state.inputText.length,
                                    ),
                                  ),
                            onChanged: (text) {
                              ref
                                  .read(interpretViewModelProvider.notifier)
                                  .setInputText(text);
                            },
                            onSubmitted: (text) {
                              ref
                                  .read(interpretViewModelProvider.notifier)
                                  .translateText(text);
                            },
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: '源语言',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
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
                                    text: state.translatedText,
                                  )
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: state.translatedText.length,
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
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
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
        ),
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

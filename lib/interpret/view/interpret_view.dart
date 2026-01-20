import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aif2f/components/icon/icon_text.dart';
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

  // 语言选择器的全局键
  static final GlobalKey _languageSelectorKey = GlobalKey();

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
                  Expanded(
                    child: Text(
                      '欢迎使用AI传译',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: MediaQuery.of(context).size.width < 600
                                ? 20
                                : 24,
                          ),
                    ),
                  ),
                  // 状态指示器
                  if (state.isProcessing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            state.statusMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? 4 : 8),
              Text(
                '轻松实现多语言翻译',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              ),
              // 语言选择卡片
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 8 : 12,
                  ),
                  child: MediaQuery.of(context).size.width < 600
                      // 移动端：垂直布局
                      ? Column(
                          children: [
                            _buildLanguageSelector(ref, context),
                            const SizedBox(height: 12),
                            _buildTranslateButton(context, ref),
                            const SizedBox(height: 12),
                            _buildRecordButton(context, ref),
                            const SizedBox(height: 12),
                            _buildLayoutPopupWindow(),
                          ],
                        )
                      // 桌面端：水平布局
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageSelector(ref, context),
                            const SizedBox(width: 16),
                            _buildTranslateButton(context, ref),
                            const SizedBox(width: 16),
                            _buildRecordButton(context, ref),
                            const SizedBox(width: 16),
                            Expanded(child: _buildLayoutPopupWindow()),
                          ],
                        ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              ),
              // 文本输入/输出卡片
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                                      TextEditingController(
                                          text: state.inputText,
                                        )
                                        ..selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: state.inputText.length,
                                              ),
                                            ),
                                  onChanged: (text) {
                                    ref
                                        .read(
                                          interpretViewModelProvider.notifier,
                                        )
                                        .setInputText(text);
                                  },
                                  onSubmitted: (text) {
                                    ref
                                        .read(
                                          interpretViewModelProvider.notifier,
                                        )
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
                                          MediaQuery.of(context).size.width <
                                              600
                                          ? 14
                                          : 16,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
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
                        indent: MediaQuery.of(context).size.width < 600
                            ? 12
                            : 24,
                        endIndent: MediaQuery.of(context).size.width < 600
                            ? 12
                            : 24,
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
                                        ..selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                    state.translatedText.length,
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
                                          MediaQuery.of(context).size.width <
                                              600
                                          ? 14
                                          : 16,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
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
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(WidgetRef ref, BuildContext context) {
    return SizedBox(
      width: 120,
      child: MouseRegion(
        key: _languageSelectorKey,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showLanguageSelector(context, ref),
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
                    width: 30,
                    child: Center(
                      child: Text(
                        _languageCodes[ref
                                .watch(interpretViewModelProvider)
                                .sourceLanguage] ??
                            ref
                                .watch(interpretViewModelProvider)
                                .sourceLanguage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(buttonContext).colorScheme.primary,
                        ),
                      ),
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
                    width: 30,
                    child: Center(
                      child: Text(
                        _languageCodes[ref
                                .watch(interpretViewModelProvider)
                                .targetLanguage] ??
                            ref
                                .watch(interpretViewModelProvider)
                                .targetLanguage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(buttonContext).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutPopupWindow() {
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
                                  IconButton(
                                    onPressed: () {
                                      // 双面板
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

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpretViewModelProvider);
    String sourceLanguage = state.sourceLanguage;
    String targetLanguage = state.targetLanguage;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('语言选择'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 源语言选择
            DropdownButtonFormField<String>(
              value: sourceLanguage,
              decoration: const InputDecoration(labelText: '源语言'),
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(value: lang, child: Text(lang)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null && value != targetLanguage) {
                  sourceLanguage = value;
                }
              },
            ),
            const SizedBox(height: 16),
            // 目标语言选择
            DropdownButtonFormField<String>(
              value: targetLanguage,
              decoration: const InputDecoration(labelText: '目标语言'),
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(value: lang, child: Text(lang)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null && value != sourceLanguage) {
                  targetLanguage = value;
                }
              },
            ),
            const SizedBox(height: 16),
            // 交换语言按钮
            ElevatedButton.icon(
              onPressed: () {
                final temp = sourceLanguage;
                sourceLanguage = targetLanguage;
                targetLanguage = temp;
                // 重新构建对话框以更新UI
                Navigator.pop(dialogContext);
                _showLanguageSelector(context, ref);
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('交换语言'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(interpretViewModelProvider.notifier)
                  .setLanguages(sourceLanguage, targetLanguage);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _swapLanguages(WidgetRef ref) {
    // 调用 ViewModel 的语言交换方法
    ref.read(interpretViewModelProvider.notifier).swapLanguages();
  }

  /// 构建翻译按钮
  Widget _buildTranslateButton(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final state = ref.watch(interpretViewModelProvider);
    final isProcessing = state.isProcessing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isProcessing
            ? null
            : () {
                final text = state.inputText.trim();
                if (text.isNotEmpty) {
                  ref
                      .read(interpretViewModelProvider.notifier)
                      .translateText(text);
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMobile ? double.infinity : 140,
          height: isMobile ? 48 : 44,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              if (isMobile) const SizedBox(width: 8),
              if (isMobile)
                Text(
                  isProcessing ? '翻译中...' : '翻译',
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
          width: isMobile ? double.infinity : 140,
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
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
            boxShadow: [
              BoxShadow(
                color: isRecording
                    ? Colors.red.withOpacity(0.3)
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
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
                  isRecording ? '录音中...' : '录音',
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
}

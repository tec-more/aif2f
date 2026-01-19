import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/components/icon/icon_text.dart';
import 'package:aif2f/components/menu/scene_menu.dart';
import 'package:aif2f/components/menu/user_menu.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/interpret/viewmodel/interpret_view_model.dart';

/// 传译场景页面
@RoutePage(name: 'InterpretRoute')
class InterpretView extends StatefulWidget {
  const InterpretView({super.key});

  @override
  State<InterpretView> createState() => _InterpretViewState();
}

class _InterpretViewState extends State<InterpretView> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  final GlobalKey _languageSelectorKey = GlobalKey();

  late InterpretViewModel _viewModel;

  String _sourceLanguage = '英语';
  String _targetLanguage = '中文';

  final List<String> _languages = [
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
  final Map<String, String> _languageCodes = {
    '英语': 'EN',
    '中文': 'ZH',
    '日语': 'JA',
    '韩语': 'KO',
    '法语': 'FR',
    '德语': 'DE',
    '西班牙语': 'ES',
    '俄语': 'RU',
  };

  @override
  void initState() {
    super.initState();
    _viewModel = InterpretViewModel();

    // 初始化翻译服务
    _viewModel.initialize();

    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {
      // 更新输入文本和翻译文本
      _targetController.text = _viewModel.translatedText;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_viewModel.isProcessing)
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
                            _viewModel.statusMessage,
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
                            _buildLanguageSelector(),
                            const SizedBox(height: 12),
                            _buildTranslateButton(),
                            const SizedBox(height: 12),
                            _buildRecordButton(),
                            const SizedBox(height: 12),
                            _buildLayoutPopupWindow(),
                          ],
                        )
                      // 桌面端：水平布局
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageSelector(),
                            const SizedBox(width: 16),
                            _buildTranslateButton(),
                            const SizedBox(width: 16),
                            _buildRecordButton(),
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
                                  controller: _sourceController,
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
                                  controller: _targetController,
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

  Widget _buildLanguageSelector() {
    return SizedBox(
      width: 120,
      child: MouseRegion(
        key: _languageSelectorKey,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showLanguageSelector(),
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
                        _languageCodes[_sourceLanguage] ?? _sourceLanguage,
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
                        _languageCodes[_targetLanguage] ?? _targetLanguage,
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
                                    icon: const _TwoPanelsIcon(),
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
                                    icon: const _TextLayout1Icon(),
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
                                    icon: const _TextLayout2Icon(),
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
                                    icon: const _TextLayout3Icon(),
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
                                    icon: const _TextLayout4Icon(),
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

  void _showLanguageSelector() {
    // 获取MouseRegion的位置信息
    final RenderBox? selectorRenderBox =
        _languageSelectorKey.currentContext?.findRenderObject() as RenderBox?;

    if (selectorRenderBox == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final selectorPosition = selectorRenderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    // 计算可用宽度和最佳宽度
    const double desiredWidth = 600;
    final double screenWidth = overlay.size.width;
    final double availableWidth = screenWidth - selectorPosition.dx;

    // 如果从左边缘开始放不下，计算合适的宽度和位置
    double actualWidth = desiredWidth;
    double horizontalOffset = 0;

    if (availableWidth < desiredWidth) {
      // 尝试向左移动菜单，使其右边缘对齐屏幕右边缘
      horizontalOffset = desiredWidth - availableWidth;

      // 如果左移后仍然放不下（MouseRegion太靠右），则缩小宽度
      if (selectorPosition.dx < horizontalOffset) {
        horizontalOffset = selectorPosition.dx; // 最多左移到屏幕左边缘
        actualWidth = screenWidth; // 使用全屏宽度
      }
    }

    // 计算弹出框位置：从MouseRegion左下方弹出
    final position =
        RelativeRect.fromRect(
          Rect.fromLTWH(
            selectorPosition.dx,
            selectorPosition.dy,
            selectorRenderBox.size.width,
            selectorRenderBox.size.height,
          ),
          Offset.zero & overlay.size,
        ).shift(
          Offset(
            -horizontalOffset, // 左对齐，根据需要向左偏移
            selectorRenderBox.size.height, // 向下偏移，使菜单在MouseRegion下方
          ),
        );

    // 在StatefulBuilder外部创建临时变量
    String tempSourceLanguage = _sourceLanguage;
    String tempTargetLanguage = _targetLanguage;

    // 保存外部组件的setState方法引用
    final outerSetState = setState;

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: Material(
            child: Container(
              width: actualWidth,
              height: 500,
              constraints: BoxConstraints(
                minWidth: 300,
                maxWidth: screenWidth - 16, // 留出一些边距
              ),
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      // 标题
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '选择语言',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      // 左右分栏的语言选择区域
                      Expanded(
                        child: Row(
                          children: [
                            // 左侧：源语言选择
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.mic_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '源语言',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      itemCount: _languages.length,
                                      itemBuilder: (context, index) {
                                        final language = _languages[index];
                                        final isSelected =
                                            language == tempSourceLanguage;

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              tempSourceLanguage = language;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _languageCodes[language] ??
                                                      language,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_rounded,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    size: 18,
                                                  )
                                                else
                                                  const SizedBox(width: 18),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 中间：交换按钮
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          final temp = tempSourceLanguage;
                                          tempSourceLanguage =
                                              tempTargetLanguage;
                                          tempTargetLanguage = temp;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.compare_arrows_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 右侧：目标语言选择
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.translate_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '目标语言',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      itemCount: _languages.length,
                                      itemBuilder: (context, index) {
                                        final language = _languages[index];
                                        final isSelected =
                                            language == tempTargetLanguage;

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              tempTargetLanguage = language;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _languageCodes[language] ??
                                                      language,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_rounded,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    size: 12,
                                                  )
                                                else
                                                  const SizedBox(width: 18),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // 底部确认按钮
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              // ✅ 使用新方法一次性设置两种语言，避免发送两次WebSocket消息
                              await _viewModel.setLanguages(
                                tempSourceLanguage,
                                tempTargetLanguage,
                              );

                              outerSetState(() {
                                _sourceLanguage = tempSourceLanguage;
                                _targetLanguage = tempTargetLanguage;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '确认',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
      elevation: 8,
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      // 同时交换文本内容
      final tempText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = tempText;
    });

    // 更新 ViewModel 的语言设置
    _viewModel.swapLanguages();
  }

  /// 构建翻译按钮
  Widget _buildTranslateButton() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isProcessing = _viewModel.isProcessing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isProcessing
            ? null
            : () {
                final text = _sourceController.text.trim();
                if (text.isNotEmpty) {
                  _viewModel.translateText(text);
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
  Widget _buildRecordButton() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isRecording = _viewModel.isProcessing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _viewModel.toggleRecording();
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

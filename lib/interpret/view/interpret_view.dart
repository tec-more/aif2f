import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/scene/view/scene_menu.dart';
import 'package:aif2f/user/view/user_menu.dart';

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

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎标题
              Text(
                '欢迎使用AI传译',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('轻松实现多语言翻译', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              // 语言选择卡片
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildLanguageSelector()),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _translate,
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            '开始',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLayoutPopupWindow()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 文本输入/输出卡片
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    children: [
                      // 源语言输入区
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.mic,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _sourceLanguage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TextField(
                                  controller: _sourceController,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    hintText: '请输入要翻译的文本...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
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
                        indent: 24,
                        endIndent: 24,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      // 目标语言输出区
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.translate,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _targetLanguage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      if (_targetController.text.isNotEmpty) {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: _targetController.text,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text('已复制到剪贴板'),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TextField(
                                  controller: _targetController,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    hintText: '翻译结果将显示在这里...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showLanguageSelector(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 源语言
              Expanded(
                child: Center(
                  child: Text(
                    _sourceLanguage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              // 翻译方向箭头
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),

              // 目标语言
              Expanded(
                child: Center(
                  child: Text(
                    _targetLanguage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
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
          tooltip: '页面样式设置',
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    // 在StatefulBuilder外部创建临时变量
    String tempSourceLanguage = _sourceLanguage;
    String tempTargetLanguage = _targetLanguage;

    // 保存外部组件的setState方法引用
    final outerSetState = setState;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部指示条
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标题
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '选择语言',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 左右分栏的语言选择区域
                  SizedBox(
                    height: 400, // 固定高度，确保模态框大小合适
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            // 左侧：源语言选择
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.mic_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '源语言',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
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
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  language,
                                                  style: TextStyle(
                                                    fontSize: 16,
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
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.check_rounded,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                      size: 20,
                                                    ),
                                                  )
                                                else
                                                  const SizedBox(
                                                    width: 36,
                                                  ), // 保持对齐
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

                            // 中间分隔线和交换按钮
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),

                            // 交换按钮
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.compare_arrows_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),

                            // 右侧：目标语言选择
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.translate_rounded,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '目标语言',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
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
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  language,
                                                  style: TextStyle(
                                                    fontSize: 16,
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
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.check_rounded,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                      size: 20,
                                                    ),
                                                  )
                                                else
                                                  const SizedBox(
                                                    width: 36,
                                                  ), // 保持对齐
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 底部确认按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // 使用外部组件的setState更新实际状态
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '确认',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
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
  }

  void _translate() {
    if (_sourceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('请输入要翻译的文本'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 模拟翻译（实际使用时需要接入翻译API）
    setState(() {
      _targetController.text = '【模拟翻译】${_sourceController.text}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('翻译完成'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// 自定义双面板图标 - 两个左右排列的空心矩形框
class _TwoPanelsIcon extends StatelessWidget {
  const _TwoPanelsIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _TwoPanelsPainter());
  }
}

class _TwoPanelsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 计算每个方框的大小
    final boxWidth = (size.width - 6) / 2; // 两个框，中间间隔2
    final boxHeight = size.height - 4;

    // 绘制左边的方框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 2, boxWidth, boxHeight),
        const Radius.circular(2),
      ),
      paint,
    );

    // 绘制右边的方框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxWidth + 4, 2, boxWidth, boxHeight),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局1 - 分为上下两部分，上面部分左边是一个实心矩形，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分同上面部分
class _TextLayout1Icon extends StatelessWidget {
  const _TextLayout1Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout1Painter(),
    );
  }
}

class _TextLayout1Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final rectWidth = 6.0;
    final rectHeight = halfHeight - padding * 2;

    // 上半部分
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight / 2 + 2),
      strokePaint,
    );

    // 下半部分
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, halfHeight + padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight + halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight + halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight + halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight + halfHeight / 2 + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局2 - 分为上下两部分，上面部分左边是一个实心三角形，箭头向右，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分同上面部分
class _TextLayout2Icon extends StatelessWidget {
  const _TextLayout2Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout2Painter(),
    );
  }
}

class _TextLayout2Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final arrowSize = 6.0;

    // 上半部分
    // 左边：向右的实心三角形箭头
    final upperArrowCenterY = halfHeight / 2;
    final upperArrowPath = Path();
    upperArrowPath.moveTo(padding, upperArrowCenterY - arrowSize / 2);
    upperArrowPath.lineTo(padding + arrowSize, upperArrowCenterY);
    upperArrowPath.lineTo(padding, upperArrowCenterY + arrowSize / 2);
    upperArrowPath.close();
    canvas.drawPath(upperArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, upperArrowCenterY - 2),
      Offset(size.width - padding, upperArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, upperArrowCenterY + 2),
      Offset(size.width - 6, upperArrowCenterY + 2),
      strokePaint,
    );

    // 下半部分
    // 左边：向右的实心三角形箭头
    final lowerArrowCenterY = halfHeight + halfHeight / 2;
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(padding, lowerArrowCenterY - arrowSize / 2);
    lowerArrowPath.lineTo(padding + arrowSize, lowerArrowCenterY);
    lowerArrowPath.lineTo(padding, lowerArrowCenterY + arrowSize / 2);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY - 2),
      Offset(size.width - padding, lowerArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY + 2),
      Offset(size.width - 6, lowerArrowCenterY + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局3 - 分为上下两部分，上面部分左边是一个实心矩形，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
// 下面部分左边是一个实心三角形，箭头向右，右边在分为上下2行，上面是一个长横线，下面是一个短横线；
class _TextLayout3Icon extends StatelessWidget {
  const _TextLayout3Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout3Painter(),
    );
  }
}

class _TextLayout3Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 2.0;
    final rectWidth = 6.0;
    final rectHeight = halfHeight - padding * 2;
    final arrowSize = 6.0;

    // 上半部分 - 左边实心矩形 + 右边两条横线
    // 左边：实心矩形
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, rectWidth, rectHeight),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 - 2),
      Offset(size.width - padding, halfHeight / 2 - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + rectWidth + 2, halfHeight / 2 + 2),
      Offset(size.width - 6, halfHeight / 2 + 2),
      strokePaint,
    );

    // 下半部分 - 左边向右的实心三角形箭头 + 右边两条横线
    final lowerArrowCenterY = halfHeight + halfHeight / 2;
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(padding, lowerArrowCenterY - arrowSize / 2);
    lowerArrowPath.lineTo(padding + arrowSize, lowerArrowCenterY);
    lowerArrowPath.lineTo(padding, lowerArrowCenterY + arrowSize / 2);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);

    // 右边上方：长横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY - 2),
      Offset(size.width - padding, lowerArrowCenterY - 2),
      strokePaint,
    );

    // 右边下方：短横线
    canvas.drawLine(
      Offset(padding + arrowSize + 2, lowerArrowCenterY + 2),
      Offset(size.width - 6, lowerArrowCenterY + 2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 文本布局4 - 分为上下两部分，上面部分分为2行，上面一行是向上的一个实心箭头，接连一条竖线，竖线连接一条横线，横线处于上面部分的最底端，箭头底部中央和竖线相连，竖线和上半部分横线相连；
// 下面部分分为上下2行，上面一行是一条横线，横线处于下面部分的最顶端，该横线连接一条竖线，竖线连接一个向下的实心箭头；
class _TextLayout4Icon extends StatelessWidget {
  const _TextLayout4Icon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TextLayout4Painter(),
    );
  }
}

class _TextLayout4Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 分为上下两部分
    final halfHeight = size.height / 2;
    final padding = 1.0;
    final centerX = size.width / 2;
    final arrowWidth = 6.0;
    final arrowHeight = 4.0;
    final lineWidth = 1.5; // 横线的厚度

    // 上半部分 - 向上实心箭头 → 竖线 → 横线
    // 计算上半部分的各元素位置
    final upperArrowBottomY = halfHeight / 2 - arrowHeight / 2; // 箭头底部中央
    final upperArrowTopY = upperArrowBottomY - arrowHeight; // 箭头顶部
    final upperLineY = halfHeight - padding - lineWidth; // 上半部分底部的横线

    // 向上实心箭头
    final upperArrowPath = Path();
    upperArrowPath.moveTo(centerX - arrowWidth / 2, upperArrowBottomY);
    upperArrowPath.lineTo(centerX, upperArrowTopY);
    upperArrowPath.lineTo(centerX + arrowWidth / 2, upperArrowBottomY);
    upperArrowPath.close();
    canvas.drawPath(upperArrowPath, fillPaint);

    // 箭头底部中央到横线的竖线
    canvas.drawLine(
      Offset(centerX, upperArrowBottomY),
      Offset(centerX, upperLineY),
      strokePaint,
    );

    // 上半部分底部的横线
    canvas.drawLine(
      Offset(padding, upperLineY),
      Offset(size.width - padding, upperLineY),
      strokePaint,
    );

    // 下半部分 - 横线 → 竖线 → 向下实心箭头
    // 计算下半部分的各元素位置
    final lowerLineY = halfHeight + padding + lineWidth; // 下半部分顶部的横线
    final lowerArrowTopY =
        halfHeight + halfHeight / 2 + arrowHeight / 2; // 箭头顶部中央
    final lowerArrowBottomY = lowerArrowTopY + arrowHeight; // 箭头底部

    // 下半部分顶部的横线
    canvas.drawLine(
      Offset(padding, lowerLineY),
      Offset(size.width - padding, lowerLineY),
      strokePaint,
    );

    // 横线到箭头顶部中央的竖线
    canvas.drawLine(
      Offset(centerX, lowerLineY),
      Offset(centerX, lowerArrowTopY),
      strokePaint,
    );

    // 向下实心箭头
    final lowerArrowPath = Path();
    lowerArrowPath.moveTo(centerX - arrowWidth / 2, lowerArrowTopY);
    lowerArrowPath.lineTo(centerX, lowerArrowBottomY);
    lowerArrowPath.lineTo(centerX + arrowWidth / 2, lowerArrowTopY);
    lowerArrowPath.close();
    canvas.drawPath(lowerArrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

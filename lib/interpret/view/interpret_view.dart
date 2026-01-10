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
      backgroundColor: Theme.of(context).colorScheme.background,
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
                                  const SizedBox(width: 12),
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
                                        ).colorScheme.surfaceVariant,
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

  void _showLanguageSelector() {
    // 在StatefulBuilder外部创建临时变量
    String tempSourceLanguage = _sourceLanguage;
    String tempTargetLanguage = _targetLanguage;

    // 保存外部组件的setState方法引用
    final outerSetState = this.setState;

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
                        child: Text(
                          '确认',
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

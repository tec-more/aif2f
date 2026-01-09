import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('AI传译'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          SceneMenu(selectedScene: SceneType.interpretation),
          const UserMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 语言选择区

            // 翻译文本框
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildLanguageDropdown(
                          value: _sourceLanguage,
                          onChanged: (value) {
                            setState(() {
                              _sourceLanguage = value;
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: _swapLanguages,
                          color: Theme.of(context).primaryColor,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 20),
                        _buildLanguageDropdown(
                          value: _targetLanguage,
                          onChanged: (value) {
                            setState(() {
                              _targetLanguage = value;
                            });
                          },
                        ),
                      ],
                    ),
                    // 分割线
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // 源语言输入区
                    Expanded(
                      child: TextField(
                        controller: _sourceController,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 18, height: 1.5),
                        decoration: InputDecoration(
                          hintText: '源语言',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        onChanged: (value) {
                          // 实时翻译逻辑可以在这里添加
                        },
                      ),
                    ),

                    // 分割线
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    // 目标语言显示区
                    Expanded(
                      child: TextField(
                        controller: _targetController,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: '翻译语言',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        readOnly: true,
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

  Widget _buildLanguageDropdown({
    required String value,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        items: _languages.map((lang) {
          return DropdownMenuItem<String>(value: lang, child: Text(lang));
        }).toList(),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconEnabledColor: Theme.of(context).primaryColor,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入要翻译的文本')));
      return;
    }

    // 模拟翻译（实际使用时需要接入翻译API）
    setState(() {
      _targetController.text = '【模拟翻译】${_sourceController.text}';
    });
  }

  void _clear() {
    setState(() {
      _sourceController.clear();
      _targetController.clear();
    });
  }
}

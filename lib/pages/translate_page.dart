import 'package:flutter/material.dart';

class InterpretPage extends StatefulWidget {
  const InterpretPage({super.key});

  @override
  State<InterpretPage> createState() => _InterpretPageState();
}

class _InterpretPageState extends State<InterpretPage> {
  // 语言列表
  final List<String> _languages = [
    '中文',
    'English',
    '日本語',
    'Español',
    'Français',
    'Deutsch',
    'Русский',
    'العربية',
  ];

  // 左侧：电脑声音传译设置
  String _computerSourceLanguage = '中文';
  String _computerTargetLanguage = 'English';
  String _computerSpeechText = '';
  String _computerInterpretResult = '';
  // 左侧面板的TextEditingController
  late TextEditingController _computerTextController;

  // 右侧：麦克风语音传译设置
  String _micSourceLanguage = '中文';
  String _micTargetLanguage = 'English';
  String _micSpeechText = '';
  String _micInterpretResult = '';
  // 右侧面板的TextEditingController
  late TextEditingController _micTextController;

  // 音色列表
  final List<String> _voices = ['默认', '男声', '女声', '儿童', '机器人'];
  String _selectedVoice = '默认';

  @override
  void initState() {
    super.initState();
    // 初始化TextEditingController
    _computerTextController = TextEditingController(text: _computerSpeechText);
    _micTextController = TextEditingController(text: _micSpeechText);
  }

  @override
  void dispose() {
    // 释放TextEditingController资源
    _computerTextController.dispose();
    _micTextController.dispose();
    super.dispose();
  }

  // 切换左侧语言
  void _swapComputerLanguages() {
    setState(() {
      final temp = _computerSourceLanguage;
      _computerSourceLanguage = _computerTargetLanguage;
      _computerTargetLanguage = temp;
    });
  }

  // 切换右侧语言
  void _swapMicLanguages() {
    setState(() {
      final temp = _micSourceLanguage;
      _micSourceLanguage = _micTargetLanguage;
      _micTargetLanguage = temp;
    });
  }

  // 模拟电脑声音获取
  void _startComputerSoundCapture() {
    setState(() {
      _computerSpeechText = '这是从电脑声音获取的示例文本，正在进行实时语音识别...';
      _computerInterpretResult =
          'This is an example text captured from computer sound, real-time speech recognition is in progress...';
    });
  }

  // 模拟麦克风语音输入
  void _startMicInput() {
    setState(() {
      _micSpeechText = '这是麦克风输入的示例语音，正在进行实时传译...';
      _micInterpretResult =
          'This is an example speech input from microphone, real-time interpretation is in progress...';
    });
  }

  // 传译电脑声音文本
  void _interpretComputerText() {
    setState(() {
      // 去掉无关前缀，只显示传译内容
      _computerInterpretResult = _computerSpeechText.isEmpty
          ? 'hello,World!'
          : _computerSpeechText;
    });
  }

  // 传译麦克风文本
  void _interpretMicText() {
    setState(() {
      // 去掉无关前缀，只显示传译内容
      _micInterpretResult = _micSpeechText.isEmpty
          ? 'hello,World!'
          : _micSpeechText;
    });
  }

  // 播放传译结果
  void _playInterpretation(String text, String from, String to) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('播放${from}到${to}的传译：$text')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('传译'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 主内容区域 - 左右两栏布局
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：电脑声音传译
                  _buildInterpretationPanel(
                    context,
                    icon: Icons.laptop,
                    sourceLanguage: _computerSourceLanguage,
                    targetLanguage: _computerTargetLanguage,
                    onSourceLanguageChanged: (value) {
                      if (value != null) {
                        setState(() => _computerSourceLanguage = value);
                      }
                    },
                    onTargetLanguageChanged: (value) {
                      if (value != null) {
                        setState(() => _computerTargetLanguage = value);
                      }
                    },
                    onSwapLanguages: _swapComputerLanguages,
                    speechText: _computerSpeechText,
                    interpretationResult: _computerInterpretResult,
                    onStartCapture: _startComputerSoundCapture,
                    onInterpret: _interpretComputerText,
                    onPlayInterpretation: () {
                      if (_computerInterpretResult.isNotEmpty) {
                        _playInterpretation(
                          _computerInterpretResult,
                          _computerSourceLanguage,
                          _computerTargetLanguage,
                        );
                      }
                    },
                    onTextChanged: (value) {
                      setState(() {
                        _computerSpeechText = value;
                        // 这里可以直接调用传译函数，或者添加防抖处理
                        _interpretComputerText();
                      });
                    },
                    textController: _computerTextController,
                  ),

                  const SizedBox(width: 20),

                  // 右侧：麦克风语音传译
                  _buildInterpretationPanel(
                    context,
                    icon: Icons.mic,
                    sourceLanguage: _micSourceLanguage,
                    targetLanguage: _micTargetLanguage,
                    onSourceLanguageChanged: (value) {
                      if (value != null) {
                        setState(() => _micSourceLanguage = value);
                      }
                    },
                    onTargetLanguageChanged: (value) {
                      if (value != null) {
                        setState(() => _micTargetLanguage = value);
                      }
                    },
                    onSwapLanguages: _swapMicLanguages,
                    speechText: _micSpeechText,
                    interpretationResult: _micInterpretResult,
                    onStartCapture: _startMicInput,
                    onInterpret: _interpretMicText,
                    onPlayInterpretation: () {
                      if (_micInterpretResult.isNotEmpty) {
                        _playInterpretation(
                          _micInterpretResult,
                          _micSourceLanguage,
                          _micTargetLanguage,
                        );
                      }
                    },
                    onTextChanged: (value) {
                      setState(() {
                        _micSpeechText = value;
                        _interpretMicText();
                      });
                    },
                    textController: _micTextController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 音色选择
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVoice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '播报音色',
                    ),
                    items: _voices.map((voice) {
                      return DropdownMenuItem(value: voice, child: Text(voice));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedVoice = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建传译面板组件
  Widget _buildInterpretationPanel(
    BuildContext context, {
    required IconData icon,
    required String sourceLanguage,
    required String targetLanguage,
    required Function(String?) onSourceLanguageChanged,
    required Function(String?) onTargetLanguageChanged,
    required Function() onSwapLanguages,
    required String speechText,
    required String interpretationResult,
    required Function() onStartCapture,
    required Function() onInterpret,
    required Function() onPlayInterpretation,
    required Function(String) onTextChanged,
    required TextEditingController textController,
  }) {
    return Expanded(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 图标和语言选择区（靠右布局）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：图标
                  Icon(icon, color: Theme.of(context).primaryColor, size: 24),

                  // 右侧：语言选择区
                  Row(
                    children: [
                      // 源语言
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          initialValue: sourceLanguage,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '源',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          items: _languages.map((language) {
                            return DropdownMenuItem(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                          onChanged: onSourceLanguageChanged,
                          isDense: true,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 切换语言按钮
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: onSwapLanguages,
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                      const SizedBox(width: 10),

                      // 目标语言
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          initialValue: targetLanguage,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '目标',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          items: _languages.map((language) {
                            return DropdownMenuItem(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                          onChanged: onTargetLanguageChanged,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 合并源内容和传译结果到一个文本框内，一行原文一行传译，放在图标和转换功能下面
              Expanded(
                child: Card(
                  elevation: 2,
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 原文（一行，可编辑）
                          TextField(
                            controller: textController,
                            onChanged: onTextChanged,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '你好，世界！',
                              hintStyle: const TextStyle(fontSize: 18),
                              // 移除可能导致性能问题的不必要装饰
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 18),
                            keyboardType: TextInputType.text,
                            maxLines: 1,
                            // 优化输入性能
                            textInputAction: TextInputAction.done,
                            // 启用自动对焦
                            autofocus: true,
                          ),

                          // 传译（下一行）
                          Text(
                            interpretationResult.isEmpty
                                ? 'hello,World!'
                                : interpretationResult,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                            ),
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
  }
}

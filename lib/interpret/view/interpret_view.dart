import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:aif2f/interpret/model/interpret_model.dart';
import 'package:aif2f/interpret/viewmodel/interpret_view_model.dart';
import 'package:aif2f/scene/model/scene_model.dart';
import 'package:aif2f/scene/view/scene_menu.dart';
import 'package:aif2f/user/view/user_menu.dart';

/// 传译功能的视图
@RoutePage(name: 'InterpretRoute')
class InterpretView extends StatelessWidget {
  const InterpretView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InterpretViewModel(),
      child: const _InterpretViewContent(),
    );
  }
}

class _InterpretViewContent extends StatelessWidget {
  const _InterpretViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<InterpretViewModel>(context);
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI传译'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 场景菜单按钮
          SceneMenu(selectedScene: SceneType.interpretation),
          // 用户菜单按钮
          const UserMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 语言选择区
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 源语言选择
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: viewModel.config.sourceLanguage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '源语言',
                  ),
                  items: supportedLanguages.map((language) {
                    return DropdownMenuItem(
                      value: language.code,
                      child: Text(language.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setSourceLanguage(value);
                    }
                  },
                ),
              ),

              // 语言切换按钮
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: viewModel.swapLanguages,
                color: Theme.of(context).primaryColor,
              ),

              // 目标语言选择
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: viewModel.config.targetLanguage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '目标语言',
                  ),
                  items: supportedLanguages.map((language) {
                    return DropdownMenuItem(
                      value: language.code,
                      child: Text(language.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setTargetLanguage(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 翻译结果区 - 一个文本框，上面为源语言文本，下面为目标语言文本
          Expanded(
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 源语言文本
                    Text(
                      viewModel.currentTranslation?.sourceText ?? '请输入或开始语音翻译',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 分割线
                    const Divider(),
                    const SizedBox(height: 10),
                    // 目标语言文本
                    Text(
                      viewModel.currentTranslation?.targetText ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 输入区域
          TextField(
            controller: textController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '输入文本',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    viewModel.translateText(text);
                  }
                },
              ),
            ),
            onSubmitted: (value) {
              final text = value.trim();
              if (text.isNotEmpty) {
                viewModel.translateText(text);
              }
            },
          ),

          const SizedBox(height: 20),

          // 操作按钮区
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 设备输出声音翻译按钮
              ElevatedButton.icon(
                onPressed: viewModel.toggleDeviceOutputCapture,
                icon: Icon(
                  viewModel.isCapturingDeviceOutput
                      ? Icons.stop
                      : Icons.speaker,
                ),
                label: Text(
                  viewModel.isCapturingDeviceOutput ? '停止设备输出翻译' : '设备输出翻译',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.isCapturingDeviceOutput
                      ? Colors.red
                      : null,
                ),
              ),

              // 设备输入声音翻译按钮
              ElevatedButton.icon(
                onPressed: viewModel.toggleDeviceInputCapture,
                icon: Icon(
                  viewModel.isCapturingDeviceInput ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  viewModel.isCapturingDeviceInput ? '停止设备输入翻译' : '设备输入翻译',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.isCapturingDeviceInput
                      ? Colors.red
                      : null,
                ),
              ),

              // 播放翻译结果按钮
              ElevatedButton.icon(
                onPressed: viewModel.playTranslation,
                icon: const Icon(Icons.volume_up),
                label: const Text('播放翻译'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 音色选择区
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: viewModel.config.selectedVoice,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '播报音色',
                  ),
                  items: supportedVoices.map((voice) {
                    return DropdownMenuItem(
                      value: voice.id,
                      child: Text(voice.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setSelectedVoice(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 语速和语调调整区
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 语速调整
              Row(
                children: [
                  const Text('语速: '),
                  Expanded(
                    child: Slider(
                      value: viewModel.config.voiceSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: viewModel.config.voiceSpeed.toStringAsFixed(1),
                      onChanged: viewModel.setVoiceSpeed,
                    ),
                  ),
                ],
              ),

              // 语调调整
              Row(
                children: [
                  const Text('语调: '),
                  Expanded(
                    child: Slider(
                      value: viewModel.config.voicePitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: viewModel.config.voicePitch.toStringAsFixed(1),
                      onChanged: viewModel.setVoicePitch,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 自动播放开关
          SwitchListTile(
            title: const Text('自动播放翻译结果'),
            value: viewModel.config.isAutoPlay,
            onChanged: (_) => viewModel.toggleAutoPlay(),
            activeThumbColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
      ),
    );
  }
}

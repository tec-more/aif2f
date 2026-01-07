import 'package:flutter/material.dart';

class SceneSelectionPage extends StatelessWidget {
  const SceneSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('场景选择'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildSceneCard(
              context,
              icon: Icons.mic,
              title: '演讲',
              description: '演讲提示词与内容总结',
              color: Colors.blue,
              sceneId: 'speech',
            ),
            _buildSceneCard(
              context,
              icon: Icons.groups,
              title: '会议',
              description: '会议纪要与重点总结',
              color: Colors.green,
              sceneId: 'meeting',
            ),
            _buildSceneCard(
              context,
              icon: Icons.people,
              title: '面试',
              description: '面试问题与回答建议',
              color: Colors.orange,
              sceneId: 'interview',
            ),
            _buildSceneCard(
              context,
              icon: Icons.event,
              title: '活动',
              description: '活动流程与内容管理',
              color: Colors.purple,
              sceneId: 'activity',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String sceneId,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () {
          // 导航到场景辅助页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SceneHelperPage(sceneId: sceneId, sceneTitle: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SceneHelperPage extends StatefulWidget {
  final String sceneId;
  final String sceneTitle;

  const SceneHelperPage({
    super.key,
    required this.sceneId,
    required this.sceneTitle,
  });

  @override
  State<SceneHelperPage> createState() => _SceneHelperPageState();
}

class _SceneHelperPageState extends State<SceneHelperPage> {
  final TextEditingController _inputController = TextEditingController();
  String _suggestion = '';
  String _summary = '';

  // 提示词库
  final Map<String, List<String>> _promptLibrary = {
    'speech': [
      '开场问候：大家好，很高兴在这里与大家分享...',
      '自我介绍：我是...，今天我将为大家带来关于...的分享',
      '核心观点：今天我想重点强调的是...',
      '案例分析：让我们来看一个实际案例...',
      '总结升华：通过今天的分享，我希望大家能够...',
    ],
    'meeting': [
      '会议开场：感谢大家参加今天的会议，本次会议主要讨论...',
      '议题介绍：第一个议题是...',
      '讨论引导：大家对这个问题有什么看法？',
      '决策确认：基于刚才的讨论，我们决定...',
      '行动安排：接下来我们需要...',
    ],
    'interview': [
      '自我介绍：您好，我是...，毕业于...专业',
      '项目经验：在...项目中，我负责...',
      '技能展示：我熟练掌握...技术',
      '职业规划：我的职业目标是...',
      '问题反问：我想了解一下贵公司的...',
    ],
    'activity': [
      '活动开场：欢迎大家参加今天的...活动',
      '流程介绍：本次活动将分为...个环节',
      '互动引导：接下来让我们一起...',
      '抽奖环节：现在是激动人心的抽奖环节...',
      '活动总结：感谢大家的参与，今天的活动...',
    ],
  };

  void _generateSuggestion() {
    final prompts = _promptLibrary[widget.sceneId] ?? [];
    if (prompts.isNotEmpty) {
      setState(() {
        _suggestion = prompts.join('\n\n');
      });
    }
  }

  void _generateSummary() {
    setState(() {
      _summary =
          '【${widget.sceneTitle}总结】\n\n${_inputController.text}\n\n核心要点：\n1. 这是从输入内容中提取的要点1\n2. 这是从输入内容中提取的要点2\n3. 这是从输入内容中提取的要点3\n\n总结建议：根据以上内容，建议...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sceneTitle), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _generateSuggestion,
              icon: const Icon(Icons.lightbulb),
              label: const Text('获取提示词'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 15),
            if (_suggestion.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SingleChildScrollView(
                      child: Text(
                        _suggestion,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              '输入内容：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '请输入${widget.sceneTitle}内容...',
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _generateSummary,
              icon: const Icon(Icons.summarize),
              label: const Text('生成总结'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 15),
            if (_summary.isNotEmpty)
              Expanded(
                child: Card(
                  elevation: 3,
                  color: Colors.yellow[50],
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SingleChildScrollView(
                      child: Text(
                        _summary,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI面对面'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // 功能入口卡片
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  // 翻译功能卡片
                  _buildFunctionCard(
                    context,
                    icon: Icons.translate,
                    title: '传译',
                    description: '基础双语翻译，支持语音播报',
                    onTap: () {
                      // 导航到翻译页面
                      Navigator.pushNamed(context, '/translate');
                    },
                  ),
                  // 场景辅助卡片
                  _buildFunctionCard(
                    context,
                    icon: Icons.lightbulb,
                    title: '场景辅助',
                    description: '演讲、会议、面试、活动等场景',
                    onTap: () {
                      // 导航到场景选择页面
                      Navigator.pushNamed(context, '/scene');
                    },
                  ),
                  // 翻译历史卡片
                  _buildFunctionCard(
                    context,
                    icon: Icons.history,
                    title: '翻译历史',
                    description: '查看和管理翻译记录',
                    onTap: () {
                      // 导航到翻译历史页面
                      // Navigator.pushNamed(context, '/history');
                    },
                  ),
                  // 设置卡片
                  _buildFunctionCard(
                    context,
                    icon: Icons.settings,
                    title: '设置',
                    description: '自定义应用参数和偏好',
                    onTap: () {
                      // 导航到设置页面
                      // Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 欢迎语
            const Center(
              child: Text(
                '欢迎使用AI面对面',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '您的智能跨语言交流助手',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 构建功能卡片
  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

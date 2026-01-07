import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 用户信息区域
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/user_avatar.png'),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 15),
                const Text(
                  'AI面对面用户',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'aif2f_user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // 功能列表
          Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.history, 
                    title: '翻译历史', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications, 
                    title: '通知设置', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.voice_chat, 
                    title: '音色设置', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.language, 
                    title: '语言设置', 
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // 关于和帮助
          Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.help_outline, 
                    title: '帮助中心', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.info_outline, 
                    title: '关于我们', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.privacy_tip_outlined, 
                    title: '隐私政策', 
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    context,
                    icon: Icons.assignment_outlined, 
                    title: '用户协议', 
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // 退出登录
          Container(
            margin: const EdgeInsets.all(15),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              '版本 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {required IconData icon, required String title, required Function() onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

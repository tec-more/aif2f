import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:aif2f/scene/model/scene_model.dart';

/// 场景活动列表页面
/// 显示指定场景的所有活动
@RoutePage()
class ActivityScenePage extends StatefulWidget {
  final SceneType sceneType;

  const ActivityScenePage({super.key, required this.sceneType});

  @override
  State<ActivityScenePage> createState() => _ActivityScenePageState();
}

class _ActivityScenePageState extends State<ActivityScenePage> {
  final SceneActivityManager _activityManager = SceneActivityManager();
  List<SceneActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    // TODO: 从本地存储加载活动
    setState(() {
      _activities = _activityManager.getActivitiesByScene(widget.sceneType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getSceneTitle()),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateActivityDialog(),
            tooltip: '创建活动',
          ),
        ],
      ),
      body: _activities.isEmpty ? _buildEmptyState() : _buildActivityList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getSceneIcon(), size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无${_getSceneTitle()}',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 创建新活动',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        return ActivityCard(
          activity: _activities[index],
          onTap: () => _showActivityDetail(_activities[index]),
          onDelete: () => _deleteActivity(_activities[index]),
        );
      },
    );
  }

  void _showCreateActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateActivityDialog(
        sceneType: widget.sceneType,
        onCreated: (activity) {
          setState(() {
            _activityManager.addActivity(activity);
            _activities = _activityManager.getActivitiesByScene(
              widget.sceneType,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已创建活动"${activity.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showActivityDetail(SceneActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ActivityDetailSheet(
        activity: activity,
        onStatusChanged: (newStatus) {
          setState(() {
            final updated = activity.copyWith(status: newStatus);
            _activityManager.updateActivity(updated);
            _activities = _activityManager.getActivitiesByScene(
              widget.sceneType,
            );
          });
        },
      ),
    );
  }

  void _deleteActivity(SceneActivity activity) {
    setState(() {
      _activityManager.deleteActivity(activity.id);
      _activities = _activityManager.getActivitiesByScene(widget.sceneType);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除"${activity.title}"'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              _activityManager.addActivity(activity);
              _activities = _activityManager.getActivitiesByScene(
                widget.sceneType,
              );
            });
          },
        ),
      ),
    );
  }

  String _getSceneTitle() {
    switch (widget.sceneType) {
      case SceneType.interpretation:
        return '传译活动';
      case SceneType.presentation:
        return '演讲活动';
      case SceneType.meeting:
        return '会议活动';
      case SceneType.education:
        return '教育活动';
    }
  }

  IconData _getSceneIcon() {
    switch (widget.sceneType) {
      case SceneType.interpretation:
        return Icons.translate;
      case SceneType.presentation:
        return Icons.present_to_all;
      case SceneType.meeting:
        return Icons.meeting_room;
      case SceneType.education:
        return Icons.school;
    }
  }
}

/// 活动卡片组件
class ActivityCard extends StatelessWidget {
  final SceneActivity activity;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(activity.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 16),
                _buildStatusChip(),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color iconColor;

    switch (activity.sceneType) {
      case SceneType.interpretation:
        iconData = Icons.translate;
        iconColor = Colors.blue;
        break;
      case SceneType.presentation:
        iconData = Icons.present_to_all;
        iconColor = Colors.purple;
        break;
      case SceneType.meeting:
        iconData = Icons.meeting_room;
        iconColor = Colors.green;
        break;
      case SceneType.education:
        iconData = Icons.school;
        iconColor = Colors.orange;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String label;

    switch (activity.status) {
      case ActivityStatus.active:
        chipColor = Colors.green;
        label = '进行中';
        break;
      case ActivityStatus.paused:
        chipColor = Colors.orange;
        label = '已暂停';
        break;
      case ActivityStatus.completed:
        chipColor = Colors.blue;
        label = '已完成';
        break;
      case ActivityStatus.archived:
        chipColor = Colors.grey;
        label = '已归档';
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: chipColor.withOpacity(0.1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

/// 创建活动对话框
class CreateActivityDialog extends StatefulWidget {
  final SceneType sceneType;
  final Function(SceneActivity) onCreated;

  const CreateActivityDialog({
    super.key,
    required this.sceneType,
    required this.onCreated,
  });

  @override
  State<CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<CreateActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建活动'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSceneTitle(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '活动标题',
                  hintText: '请输入活动标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入活动标题';
                  }
                  if (value.trim().length < 2) {
                    return '标题至少需要2个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '活动描述',
                  hintText: '请输入活动描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入活动描述';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _handleCreate, child: const Text('创建')),
      ],
    );
  }

  void _handleCreate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final activity = SceneActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      sceneType: widget.sceneType,
    );

    widget.onCreated(activity);
    Navigator.pop(context);
  }

  String _getSceneTitle() {
    switch (widget.sceneType) {
      case SceneType.interpretation:
        return '创建传译活动';
      case SceneType.presentation:
        return '创建演讲活动';
      case SceneType.meeting:
        return '创建会议活动';
      case SceneType.education:
        return '创建教育活动';
    }
  }
}

/// 活动详情底部弹窗
class ActivityDetailSheet extends StatelessWidget {
  final SceneActivity activity;
  final Function(ActivityStatus) onStatusChanged;

  const ActivityDetailSheet({
    super.key,
    required this.activity,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildStatusDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            activity.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '创建于 ${_formatDateTime(activity.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButton<ActivityStatus>(
      value: activity.status,
      onChanged: (newStatus) {
        if (newStatus != null) {
          onStatusChanged(newStatus);
        }
      },
      items: ActivityStatus.values.map((status) {
        return DropdownMenuItem(value: status, child: _buildStatusItem(status));
      }).toList(),
    );
  }

  Widget _buildStatusItem(ActivityStatus status) {
    Color color;
    String label;

    switch (status) {
      case ActivityStatus.active:
        color = Colors.green;
        label = '进行中';
        break;
      case ActivityStatus.paused:
        color = Colors.orange;
        label = '已暂停';
        break;
      case ActivityStatus.completed:
        color = Colors.blue;
        label = '已完成';
        break;
      case ActivityStatus.archived:
        color = Colors.grey;
        label = '已归档';
        break;
    }

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

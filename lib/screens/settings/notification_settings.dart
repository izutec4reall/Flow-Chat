import 'package:flutter/material.dart';
import '../../utils/translations.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('notifications'))),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(context.t('conversationTones')),
            subtitle: Text(context.t('tonesSub')),
            secondary: const Icon(Icons.volume_up_outlined),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            title: Text(context.t('notificationTone')),
            subtitle: Text(context.t('defaultTone')),
            leading: const Icon(Icons.music_note_outlined),
            onTap: () {},
          ),
          SwitchListTile(
            title: Text(context.t('vibrate')),
            subtitle: Text(context.t('defaultTone')),
            secondary: const Icon(Icons.vibration),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.t('groupNotifications')),
            subtitle: Text(context.t('groupNotifSub')),
            secondary: const Icon(Icons.group_outlined),
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}

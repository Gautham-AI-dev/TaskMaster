import 'package:flutter/material.dart';

class TaskMasterSettings extends StatelessWidget {
  const TaskMasterSettings({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings & integrations')),
        body: const ListView(
          children: [
            ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('Device capabilities'),
              subtitle: Text('Local offline execution. More Android actions coming.'),
            ),
            ListTile(
              leading: Icon(Icons.extension_outlined),
              title: Text('Plugins & connectors'),
              subtitle: Text('No external integrations connected in this MVP.'),
            ),
            ListTile(
              leading: Icon(Icons.hub_outlined),
              title: Text('MCP servers & APIs'),
              subtitle: Text('Not configured. PC and cloud integration deferred.'),
            ),
            ListTile(
              leading: Icon(Icons.psychology_outlined),
              title: Text('Models'),
              subtitle: Text('Offline rule-based routing only; no AI model installed.'),
            ),
            ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Privacy & permissions'),
              subtitle: Text('Tasks are saved on-device. External app launches require approval.'),
            ),
          ],
        ),
      );
}

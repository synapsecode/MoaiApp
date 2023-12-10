import 'package:flutter/material.dart';
import 'package:moai_app/services/pushprotocol/pushprotocol_engine.dart';

class PushProtocolPlayground extends StatelessWidget {
  const PushProtocolPlayground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Protocol Playground'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              PushProtocolEngine.connectToNotificationSocket();
            },
            child: const Text('Start Listening to Notifications'),
          )
        ],
      ),
    );
  }
}

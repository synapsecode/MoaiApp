import 'package:flutter/material.dart';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';
import 'package:xmtp/xmtp.dart';

class XMTPTestFragment extends StatefulWidget {
  const XMTPTestFragment({Key? key}) : super(key: key);

  @override
  State<XMTPTestFragment> createState() => _XMTPTestFragmentState();
}

class _XMTPTestFragmentState extends State<XMTPTestFragment> {
  Conversation? currentConvo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('CURRENT-CONVO => ${currentConvo?.peer}'),
          const SizedBox(height: 50),
          // Text('Your Conversations'),

          ElevatedButton(
            onPressed: () async {
              //TODO: Fix Arbitrary Null Check
              final convs = await MoaiXMTPInterface.instance.xmtpActions!
                  .getAllConversations();
              print(convs);
            },
            child: const Text('List All Conversations'),
          ),
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () async {
                  const convAccount =
                      '0x9D471c71dCb5cf9C63b0634061F0E941B452a832';
                  //TODO: Fix Arbitrary Null Check
                  currentConvo = await MoaiXMTPInterface.instance.xmtpActions!
                      .createConversation(convAccount);
                  setState(() {});
                },
                child: const Text('Start Conversation'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  currentConvo = null;
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Close Conversation'),
              )
            ],
          ),
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (currentConvo == null) return;
                  //TODO: Fix Arbitrary Null Check
                  final msgs = await MoaiXMTPInterface.instance.xmtpActions!
                      .getAllMessages(conversation: currentConvo!);
                  print(msgs);
                },
                child: const Text('Get All Messages'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  if (currentConvo == null) return;
                  const msg = 'Hello there! This is test message 2';
                  //TODO: Fix Arbitrary Null Check
                  await MoaiXMTPInterface.instance.xmtpActions!.sendMessage(
                    conversation: currentConvo!,
                    type: 'text',
                    text: msg,
                  );
                  print('Message Sent');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Send Message'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

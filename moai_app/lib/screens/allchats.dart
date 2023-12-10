import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/screens/chatsec.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';
import 'package:xmtp/xmtp.dart';

class AllXMTPChats extends ConsumerStatefulWidget {
  const AllXMTPChats({super.key});

  @override
  ConsumerState<AllXMTPChats> createState() => _AllXMTPChatsState();
}

class _AllXMTPChatsState extends ConsumerState<AllXMTPChats> {
  TextEditingController addrC = TextEditingController();

  List<Conversation> convs = [];

  loadAllConversations() async {
    final c =
        await MoaiXMTPInterface.instance.xmtpActions!.getAllConversations();
    convs = [...c];
    setState(() {});
  }

  @override
  void initState() {
    MoaiXMTPInterface.instance.initializeXMTP().then((x) {
      loadAllConversations();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final wp = ref.watch(moaiWalletController);

    return Scaffold(
      appBar: AppBar(
        title: Text('All XMTP Chats'),
      ),
      body: Column(
        children: [
          Text(wp.accountAddress.toString()).addVerticalMargin(30),
          ...convs
              .map(
                (x) => ListTile(
                  leading: CircleAvatar(),
                  title: Text(x.peer?.hex ?? '0xNone'),
                  subtitle: Text('click here to chat'),
                  onTap: () async {
                    if (x.peer.hex == null) return;
                    final conv = await MoaiXMTPInterface.instance.xmtpActions!
                        .createConversation(x.peer!.hex);
                    Navigator.of(context).pushNewPage(
                      XMTPChatScreen(convo: conv),
                    );
                  },
                ),
              )
              .toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icons.add.toIcon(),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                contentPadding: EdgeInsets.zero,
                actionsPadding: EdgeInsets.zero,
                title: Text('Enter Account Address'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: addrC,
                      decoration: InputDecoration(hintText: '0xA9Df.....'),
                    ).addUniformMargin(20),
                    Container(
                      height: 50,
                      color: Colors.black,
                      width: double.infinity,
                      child: Text('CHAT').size(28).color(Colors.white).center(),
                    ).onClick(() async {
                      final addr = addrC.value.text;
                      final conv = await MoaiXMTPInterface.instance.xmtpActions!
                          .createConversation(addr);
                      setState(() {});
                      Navigator.pop(context);
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

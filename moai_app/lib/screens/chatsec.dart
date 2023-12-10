import 'package:flutter/material.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';
import 'package:xmtp/xmtp.dart';

class XMTPChatScreen extends StatefulWidget {
  final Conversation convo;

  const XMTPChatScreen({super.key, required this.convo});

  @override
  State<XMTPChatScreen> createState() => _XMTPChatScreenState();
}

class _XMTPChatScreenState extends State<XMTPChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  List<ChatMessage> _messages = <ChatMessage>[];

  void _handleSubmitted(String text) async {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      sender: 'you',
      animationController: AnimationController(
        duration: Duration(milliseconds: 700),
        vsync: this,
      ),
    );
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
    await MoaiXMTPInterface.instance.xmtpActions!.sendMessage(
      conversation: widget.convo,
      type: 'text',
      text: text,
    );
    print('XMTP Message Sent');
  }

  initiallyLoad() async {
    final wp = gpc.read(moaiWalletController);
    final msgs = await MoaiXMTPInterface.instance.xmtpActions!
        .getAllMessages(conversation: widget.convo);
    print(msgs);
    _messages = msgs
        .map(
          (m) => ChatMessage(
            text: m['content']['text'],
            animationController: AnimationController(
              duration: Duration(milliseconds: 700),
              vsync: this,
            ),
            sender: m['sender'],
          ),
        )
        .toList();
    setState(() {});
    print('Loaded');
  }

  initializeStream() {
    MoaiXMTPInterface.instance.xmtpActions!.streamMessages(
      conversation: widget.convo,
      onMessageReceieved: (msg) {
        final wp = gpc.read(moaiWalletController);
        final sender = msg['sender'];
        final text = msg['content']['text'];
        final isMe = sender == wp.accountAddress;
        ChatMessage message = ChatMessage(
          text: text,
          sender: isMe ? 'you' : sender,
          animationController: AnimationController(
            duration: Duration(milliseconds: 700),
            vsync: this,
          ),
        );
        setState(() {
          _messages.insert(0, message);
        });
        message.animationController.forward();
      },
    );
  }

  @override
  void initState() {
    initiallyLoad();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('XMTP Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) {
                return ChatMessage(
                  text: _messages[index].text,
                  animationController: AnimationController(
                    duration: Duration(milliseconds: 700),
                    vsync: this,
                  ),
                  sender: _messages[index].sender,
                );
              },
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Colors.purple),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type a message',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final String sender;
  final AnimationController animationController;

  ChatMessage({
    required this.text,
    required this.animationController,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final addr = (gpc.read(moaiWalletController).accountAddress!);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(
                sender.toLowerCase() == addr.toLowerCase() ? 'You' : sender,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ).limitSize(25),
              radius: 25,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sender.toLowerCase() == addr.toLowerCase() ? 'You' : sender,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w200,
                    fontSize: 16,
                  ),
                ).limitSize(200),
                Container(
                  margin: EdgeInsets.only(top: 0.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

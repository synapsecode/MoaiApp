import 'dart:async';
import 'dart:convert';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';
import 'package:xmtp/xmtp.dart' as xmtp;

class XMTPActions {
  String appID;
  xmtp.Client client;
  XMTPActions(this.appID, this.client);

  Future<List<xmtp.Conversation>> getAllConversations() async {
    final conversations = await client.listConversations();
    return conversations
        .where((c) => c.conversationId.startsWith(appID))
        .toList();
  }

  Future<xmtp.Conversation> createConversation(
    String ethAddress, {
    String? convID,
    Map<String, String>? metadata,
  }) async {
    try {
      final conversation = await client.newConversation(
        ethAddress,
        conversationId: convID != null ? "$appID/$convID" : appID,
        metadata: metadata ?? {},
      );
      return conversation;
    } catch (e) {
      rethrow;
    }
  }

  Future<StreamSubscription<xmtp.Conversation>> streamConversations({
    required Function(xmtp.Conversation) onReceieved,
  }) async {
    return client.streamConversations().listen((convo) {
      onReceieved(convo);
    });
    //Make sure to cancel the subscription once it is done
  }

  Future<List<Map>> getAllMessages({
    required xmtp.Conversation conversation,
    int? limit,
  }) async {
    List<Map> messages = [];
    final msglist = await client.listMessages(
      conversation,
      limit: limit,
    );
    for (final msg in msglist) {
      //Creation of Custom Message Object
      final jsonMsg = XMTPRatofyWalletHelpers.getMessageInJson(msg);
      messages.add(jsonMsg);
    }
    return messages;
  }

  sendMessage({
    required xmtp.Conversation conversation,
    required String type,
    String? text = '', //default
    String? res = '',
  }) async {
    await client.sendMessage(
      conversation,
      jsonEncode({
        'text': text,
        'type': type,
        'res': res,
      }),
    );
  }

  Future<StreamSubscription<xmtp.DecodedMessage>> streamMessages({
    required xmtp.Conversation conversation,
    required Function(Map) onMessageReceieved,
  }) async {
    return client.streamMessages(conversation).listen((message) {
      print('[streamMessages]::received');
      final jsonMessage = XMTPRatofyWalletHelpers.getMessageInJson(message);
      onMessageReceieved(jsonMessage);
    });
    //Make sure to cancel the subscription once it is done
  }
}

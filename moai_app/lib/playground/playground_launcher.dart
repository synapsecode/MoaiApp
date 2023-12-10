import 'package:flutter/material.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/playground/contract_playground.dart';
import 'package:moai_app/playground/huddle_playground.dart';
import 'package:moai_app/playground/pushprotocol_playground.dart';
import 'package:moai_app/playground/wallet_playground.dart';

class PlaygroundLauncher extends StatelessWidget {
  const PlaygroundLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moai Playground'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNewPage(const WalletPlayground());
            },
            child: Text('Wallet & XMTP Playground'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNewPage(const HuddlePlayground());
            },
            child: Text('Huddle01 Playground'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNewPage(const PushProtocolPlayground());
            },
            child: Text('PushProtocol Playground'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNewPage(const MoaiContractPlayground());
            },
            child: Text('MoaiContract Playground'),
          ),
        ],
      ).center(),
    );
  }
}

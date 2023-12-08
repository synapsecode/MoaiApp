import 'package:flutter/material.dart';
import 'package:moai_app/playground/wallet_playground.dart';

class PlaygroundLauncher extends StatelessWidget {
  const PlaygroundLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return const SingletPlayground();
    return const WalletPlayground();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moai_app/common/dialogs/connect2wallet.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/screens/allchats.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';

class MoaiManager {}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final wp = ref.watch(moaiWalletController);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Moai'),
      ),
      body: (!wp.isWalletActive)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ConnectToMoaiWallet.show(context);
                  },
                  child: Text('Connect Wallet'),
                )
              ],
            ).center()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNewPage(AllXMTPChats());
                  },
                  child: const Text('Go to XMTP Chat Demo'),
                ),
              ],
            ).center(),
    );
  }
}

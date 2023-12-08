// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';

class ConnectToMoaiWallet extends StatefulWidget {
  const ConnectToMoaiWallet({
    Key? key,
  }) : super(key: key);

  @override
  State<ConnectToMoaiWallet> createState() => _ConnectToMoaiWalletState();
}

class _ConnectToMoaiWalletState extends State<ConnectToMoaiWallet> {
  TextEditingController mc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final walletProvider = gpc.read(moaiWalletController);

    return AlertDialog(
      title: const Text('Connect to Wallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Moai needs you to connect your wallet to begin messaging!'),
          const SizedBox(height: 10),
          TextField(
            controller: mc,
            decoration: const InputDecoration(hintText: 'Enter Seed Phrase'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (mc.value.text.isEmpty) return;
                final z = await walletProvider.importWallet(mc.value.text);
                print(z);
                Navigator.pop(context, walletProvider.accountAddress);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Connect Wallet'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final w = await walletProvider.createWallet();
                final mnemonic = w['mnemonic'];

                final copied = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Copy Seed Phrase'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'This is your generated seed phrase. Copy it and store it in a secure location as it cannot be regenerated',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.blue[50],
                            child: Text(mnemonic),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: mnemonic),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to Clipboard!'),
                                  ),
                                );
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black),
                              child: const Text('Copy to Clipboard'),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                );
                print('Copied => $copied');
                print('AccountAddress => ${walletProvider.accountAddress}');
                Navigator.of(context).pop(walletProvider.accountAddress);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Create Moai Wallet'),
            ),
          )
        ],
      ),
      // actions: [
      //   TextButton(
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //     child: const Text('Cancel'),
      //   ),
      // ],
    );
  }
}

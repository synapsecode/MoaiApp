import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moai_app/playground/xmtp_test_fragment.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';
import 'package:xmtp/xmtp.dart' as xmtp;

class WalletPlayground extends ConsumerStatefulWidget {
  const WalletPlayground({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletPlayground> createState() => _WalletPlaygroundState();
}

class _WalletPlaygroundState extends ConsumerState<WalletPlayground> {
  TextEditingController mc = TextEditingController();
  xmtp.Client? client;

  autoLoadClient() {
    if (mounted) {
      MoaiXMTPInterface.instance.initializeXMTP().then((_) {
        setState(() {});
        print('XMTPAutoLoaded');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    autoLoadClient();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = ref.watch(moaiWalletController);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Playground'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('IsLoggedIn => ${walletProvider.isWalletActive}'),
            Text('Address => ${walletProvider.accountAddress}'),
            const SizedBox(height: 20),
            Text('PrivateKey => ${walletProvider.privateKey}'),
            const SizedBox(height: 20),
            const Text(
              'Wallet Functions',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Input Mnemonic'),
                      content: TextField(
                        controller: mc,
                        decoration: const InputDecoration(
                            hintText: 'Enter Mnemonic....'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Import'),
                        )
                      ],
                    );
                  },
                );
                if (mc.value.text.isEmpty) return;
                walletProvider.importWallet(mc.value.text);
              },
              child: const Text('Import Wallet'),
            ),
            ElevatedButton(
              onPressed: () async {
                final w = await walletProvider.createWallet();
                print(w);
              },
              child: const Text('Generate Wallet'),
            ),
            ElevatedButton(
              onPressed: () async {
                walletProvider.logout();
              },
              child: const Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () async {
                walletProvider.showWallet();
              },
              child: const Text('Show Wallet'),
            ),
            ElevatedButton(
              onPressed: () async {
                final b = await walletProvider.getBalance();
                print(b);
              },
              child: const Text('Get Balance'),
            ),
            ElevatedButton(
              onPressed: () async {
                double maticTOEthMultiplier = 0.00000038600098111706;
                await walletProvider.sendTransaction(
                  valueInEth: 0.001 * maticTOEthMultiplier,
                  receiverAddress: '0x79c775e8739253f1c8a68355df22e0e29ad7bf1d',
                );
              },
              child: const Text('Send Small Amount'),
            ),
            ElevatedButton(
              onPressed: () async {
                final hash = await walletProvider.personalSign(
                    message: 'Ratofy: SPM Demo');
                print(hash);
              },
              child: const Text('Demostrate PersonalMessage Sign'),
            ),
            const SizedBox(height: 20),
            const Text(
              'XMTP Functions',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Client => ${MoaiXMTPInterface.instance.xmtpClient}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await MoaiXMTPInterface.instance.initializeXMTP();
                setState(() {});
              },
              child: const Text('Initialize XMTP'),
            ),
            ElevatedButton(
              onPressed: () async {
                MoaiXMTPInterface.instance.terminateAll();
              },
              child: const Text('Terminate XMTP'),
            ),
            const SizedBox(height: 20),
            const XMTPTestFragment(),
          ],
        ),
      ),
    );
  }
}

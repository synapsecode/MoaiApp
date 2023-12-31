import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moai_app/controllers/user_controller.dart';
import 'package:moai_app/extensions/extensions.dart';
import 'package:moai_app/services/blockchain/contract_interface.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';

class MoaiContractPlayground extends ConsumerStatefulWidget {
  const MoaiContractPlayground({super.key});

  @override
  ConsumerState<MoaiContractPlayground> createState() =>
      _MoaiContractPlaygroundState();
}

class _MoaiContractPlaygroundState
    extends ConsumerState<MoaiContractPlayground> {
  @override
  Widget build(BuildContext context) {
    final wp = ref.watch(moaiWalletController);
    final muc = ref.watch(moaiUserController);
    final mci = ref.watch(moaiContractInterface);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Playground'),
        centerTitle: true,
      ),
      body: (wp.isWalletActive)
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    mci.getMoaiValue();
                  },
                  child: const Text('Check Value of Moai'),
                ),
                ElevatedButton(
                  onPressed: () {
                    mci.addMember(wp.accountEA!);
                  },
                  child: const Text('Enter this Moai'),
                ),
                ElevatedButton(
                  onPressed: () {
                    mci.contribute(wp.accountEA!, 0.0005);
                  },
                  child: const Text('Enter this Moai'),
                )
              ],
            )
          : const Text('Connect Wallet').size(20).center(),
    );
  }
}

import 'package:moai_app/main.dart';
import 'package:moai_app/services/pushprotocol/ppsigner.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:ethers/signers/wallet.dart' as ethers;
import 'package:push_restapi_dart/push_restapi_dart.dart';

class PushProtocolEngine {
  static generatePushWallet() async {
    final wp = gpc.read(moaiWalletController);
    final ethersWallet = ethers.Wallet.fromPrivateKey(wp.privateKey!);
    final signer = PushProtocolSigner(
      ethersWallet: ethersWallet,
      address: ethersWallet.address!,
    );

    print('EWA: ${ethersWallet!.address}');
    final user = await getUser(address: ethersWallet.address!);

    if (user == null) {
      print('Cannot get user');
      return;
    }

    String? pgpPrivateKey = null;
    if (user.encryptedPrivateKey != null) {
      pgpPrivateKey = await decryptPGPKey(
        encryptedPGPPrivateKey: user.encryptedPrivateKey!,
        wallet: getWallet(signer: signer),
      );
    }

    print('pgpPrivateKey: $pgpPrivateKey');

    final pushWallet = Wallet(
      address: ethersWallet.address,
      signer: signer,
      pgpPrivateKey: pgpPrivateKey,
    );

    print('PUSHWALLET => ${pushWallet.address}');
  }

  static Future<void> connectToNotificationSocket() async {
    final wp = gpc.read(moaiWalletController);
    final options = SocketInputOptions(
      user: wp.accountAddress!,
      env: ENV.staging,
      socketType: SOCKETTYPES.NOTIFICATION,
      socketOptions: SocketOptions(
        autoConnect: true,
        reconnectionAttempts: 5,
      ),
    );
    final pushSocket = await createSocketConnection(options);
    print('Result: $pushSocket');

    if (pushSocket != null) {
      pushSocket.connect();

      pushSocket.on(
        EVENTS.CONNECT,
        (data) {
          print(' EVENTS.CONNECT: $data');
        },
      );
      pushSocket.on(
        EVENTS.CHAT_RECEIVED_MESSAGE,
        (data) {
          print(' EVENTS.CHAT_RECEIVED_MESSAGE: $data');
        },
      );
      pushSocket.on(
        EVENTS.CHAT_GROUPS,
        (data) {
          print(' EVENTS.CHAT_GROUPS: $data');
        },
      );
      pushSocket.on(
        EVENTS.USER_FEEDS,
        (data) {
          print(' EVENTS.USER_FEEDS: $data');
        },
      );
      pushSocket.on(
        EVENTS.USER_SPAM_FEEDS,
        (data) {
          print(' EVENTS.USER_SPAM_FEEDS: $data');
        },
      );
      pushSocket.on(
        EVENTS.DISCONNECT,
        (data) {
          print(' EVENTS.DISCONNECT: $data');
        },
      );
    }
  }
}

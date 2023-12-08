import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:moai_app/common/dialogs/connect2wallet.dart';
import 'package:moai_app/controllers/user_controller.dart';
import 'package:moai_app/main.dart';
import 'package:moai_app/services/wallet/wallet_provider.dart';
import 'package:moai_app/services/xmtp/xmtp_actions.dart';
import 'package:xmtp/xmtp.dart' as xmtp;

class MoaiXMTPInterface {
  xmtp.Api? xmtpApi;
  xmtp.Client? xmtpClient;
  XMTPActions? xmtpActions;
  MoaiWalletProvider? walletProvider;

  static const String appID = 'com.example.moai';
  static MoaiXMTPInterface instance = MoaiXMTPInterface();

  initalizeWalletProvider() {
    Future.delayed(const Duration(seconds: 1), () {
      walletProvider = gpc.read(moaiWalletController);
      if (walletProvider == null) {
        print(
            'initalizeWalletProvider: WalletProvider could not be initialized');
        return;
      }
      walletProvider!.initialize();
      print('WalletProvider has been initialized!');
    });
  }

  initializeXMTP() async {
    xmtpApi = xmtp.Api.create();
    final muc = gpc.read(moaiUserController);
    if (muc.currentClient != null) {
      xmtpClient = muc.currentClient;
      print('initializeXMTP: CurrentClient already Exists. Client Mounted.');
      return;
    }
    final pkJsonString = await storage.read(key: 'ratofy_xmtp_pk');
    if (pkJsonString == null) {
      //Create a new Client
      xmtpClient = await _createXMTPClient();
      if (xmtpClient == null) {
        print('initializeXMTP::ABORT: Null XMTP Client');
        return;
      }
    } else {
      print('Using existing Client');
      final keys = xmtp.PrivateKeyBundle.fromJson(pkJsonString);
      xmtpClient = await xmtp.Client.createFromKeys(xmtpApi!, keys);
    }
    muc.setCurrentClient(xmtpClient!);
    xmtpActions = XMTPActions(appID, xmtpClient!); //Instantiating XMTP Actions
    print('CurrentUser has been set!');
  }

  terminateAll() async {
    await storage.delete(key: 'ratofy_xmtp_pk');
    await XMTPRatofyWalletHelpers.removeWalletAddress();

    final muc = gpc.read(moaiUserController);
    muc.clearcurrentClient();
    muc.clearcurrentSigner();
    await xmtpClient?.terminate();
    await xmtpApi?.terminate();
    walletProvider?.logout();
    xmtpActions = null;
    xmtpApi = null;
    xmtpClient = null;
    print('MoaiXMTPInterface instance terminated');
  }

  //=========== Helpers =============
  Future<xmtp.Client?> _createXMTPClient() async {
    // final xuc = Get.put(XMTPChatUserState());
    final muc = gpc.read(moaiUserController);
    xmtp.Signer? sng;

    if (muc.currentSigner == null) {
      String? accaddr = await showDialog<String>(
        context: navigatorKey.currentState!.context,
        builder: (cx) {
          return const ConnectToMoaiWallet();
        },
      );
      if (accaddr == null) {
        print('Aborting XMTP Client Creation as user rejected proposal');
        return null;
      } else {
        sng = await _createSigner();
      }
    } else {
      print('USING Existing XUCSigner');
      sng = muc.currentSigner!;
    }
    final c = await xmtp.Client.createFromWallet(xmtpApi!, sng);
    await storage.write(
      key: 'ratofy_xmtp_pk',
      value: c.keys.writeToJson().toString(),
    );
    muc.setCurrentSigner(sng);
    print('XUC: New Signer Set!');
    await XMTPRatofyWalletHelpers.saveWalletAddress(
      walletProvider!.accountAddress!,
    );
    print('_createXMTPClient: WalletAddress saved!');
    print('Created new XMTPClient!');
    return c;
  }

  Future<xmtp.Signer> _createSigner() async {
    if (walletProvider == null) {
      throw Exception('_createSigner: WalletProvider is NULL');
    }
    if (!walletProvider!.isWalletActive) {
      throw Exception('_createSigner: Inactive Wallet');
    }
    final signer = xmtp.Signer.create(
      walletProvider!.accountAddress!,
      (String signPM) async {
        signPM = signPM.trim();
        final hash = await walletProvider!.personalSign(message: signPM);
        print('Generated Hash => $hash');
        Uint8List byteList = Uint8List.fromList(HEX.decode(hash.substring(2)));
        return byteList;
      },
    );
    return signer;
  }
  //==================================
}

class XMTPRatofyWalletHelpers {
  static Map getMessageInJson(xmtp.DecodedMessage msg) {
    return {
      'id': msg.id,
      'sender': msg.sender.hex,
      'sentAt': msg.sentAt.millisecondsSinceEpoch,
      'content': jsonDecode(msg.content.toString()),
    };
  }

  static Future<void> saveWalletAddress(
    String address,
  ) async {
    // if (serverSync) {
    //   var r = await UserController()
    //       .editProfile({"walletAddress": address.toLowerCase()});
    //   if (!r) {
    //     throw Exception("Cannot save wallet to backend");
    //   }
    // }
    await storage.write(key: "wallet_address", value: address);
  }

  static Future<void> removeWalletAddress() async {
    await storage.delete(key: "wallet_address");
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/foundation.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hex/hex.dart';
import 'package:moai_app/main.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

final moaiWalletController =
    ChangeNotifierProvider<MoaiWalletProvider>((ref) => MoaiWalletProvider());

abstract class WalletAddressService {
  String generateMnemonic();
  Future<String?> getPrivateKey(String mnemonic);
  EthereumAddress getPublicKey(String privateKey);
}

class MoaiWalletProvider extends ChangeNotifier
    implements WalletAddressService {
  String? privateKey;
  String? _pubkey;
  RPCEngine rpcEngine = RPCEngine();

  bool get isWalletActive => privateKey != null && _pubkey != null;

  String? get accountAddress =>
      _pubkey == null ? null : checksumEthereumAddress(_pubkey!);
  EthereumAddress? get accountEA =>
      accountAddress == null ? null : EthereumAddress.fromHex(accountAddress!);

  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  @override
  Future<String?> getPrivateKey(String mnemonic) async {
    try {
      final seed = bip39.mnemonicToSeed(mnemonic);
      final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
      privateKey = HEX.encode(master.key);
      return privateKey;
    } catch (e) {
      print('WalletProvider::getPrivateKey: ErrorOccured: $e');
    }
    return null;
  }

  @override
  EthereumAddress getPublicKey(String privateKey) {
    final private = EthPrivateKey.fromHex(privateKey);
    final address = private.address;
    return address;
  }

  Future<Map> createWallet() async {
    final mnemonic = generateMnemonic();
    final pvk = await getPrivateKey(mnemonic);
    if (pvk == null) throw Exception('Incorrect Mnemonic');
    final puk = getPublicKey(pvk);

    print('========== RatofyWalletGenerated ==========');
    print('Mnemonic: $mnemonic');
    print('PrivateKey: $pvk');
    print('PublicKey/Address: $puk');
    print('===========================================');

    print('Saving WalletDetails to SharedPreferences');
    await setPrivateKey(pvk);

    _pubkey = puk.hex;
    privateKey = pvk;

    return {
      'mnemonic': mnemonic,
      'address': puk,
      'privatekey': pvk,
    };
  }

  Future<Map> importWallet(String mnemonic) async {
    final pvk = await getPrivateKey(mnemonic);
    if (pvk == null) throw Exception('Incorrect Mnemonic');
    final puk = getPublicKey(pvk);
    print('========== RatofyWallet-Imported ==========');
    print('PrivateKey: $pvk');
    print('PublicKey/Address: $puk');
    print('===========================================');
    await setPrivateKey(pvk);
    _pubkey = puk.hex;
    privateKey = pvk;
    return {
      'address': puk,
      'privatekey': pvk,
    };
  }

  Future<void> loadPrivateKey() async {
    privateKey = await storage.read(key: 'privatekey');
    if (privateKey != null) {
      _pubkey = getPublicKey(privateKey!).hex;
    }
    notifyListeners();
  }

  Future<void> setPrivateKey(String privateKey) async {
    await storage.write(key: 'privatekey', value: privateKey);
    notifyListeners();
  }

  initialize() async {
    await loadPrivateKey();
  }

  logout() async {
    await storage.delete(key: 'privatekey');
    privateKey = null;
    _pubkey = null;
    notifyListeners();
  }

  getBalance() async {
    final eth = await rpcEngine.fetchBalanceInETH(accountAddress!);
    return eth.toStringAsFixed(3);
  }

  sendTransaction({
    required String receiverAddress,
    required double valueInEth,
  }) async {
    final ethClient = RPCEngine.getWeb3Client();
    EthPrivateKey cred = EthPrivateKey.fromHex('0x$privateKey');

    EtherAmount gasPrice = await ethClient.getGasPrice();
    print('Estimated GasPrice: $gasPrice');

    final txValue = EtherAmount.fromBigInt(
      EtherUnit.wei,
      BigInt.from(valueInEth * pow(10, 18)),
    );

    await ethClient.sendTransaction(
      cred,
      Transaction(
        to: EthereumAddress.fromHex(receiverAddress),
        maxGas: 1000000,
        value: txValue,
      ),
      chainId: rpcEngine.chainID,
    );
  }

  Future<String> personalSign({required String message}) async {
    final sgn = EthSigUtil.signPersonalMessage(
      message: Uint8List.fromList(message.codeUnits),
      privateKey: privateKey!,
    );
    return sgn;
  }

  Credentials get credentials => EthPrivateKey.fromHex(privateKey!);

  void showWallet() {}
}

class RPCEngine {
  final int chainID = 80001; //POLYGON
  static const String rpcURL =
      'https://polygon-mumbai.g.alchemy.com/v2/FxMAYfEas1BSJM1WbAjkVRAe-AVG_l_k';

  static Web3Client getWeb3Client() {
    final ethClient = Web3Client(rpcURL, http.Client());
    return ethClient;
  }

  Future<double> fetchBalanceInETH(String addr) async {
    final Map<String, dynamic> data = {
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [addr, 'latest'],
      'id': 1,
    };
    final http.Response response = await http.post(
      Uri.parse(rpcURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final Map<String, dynamic> result = jsonDecode(response.body);
    if (result.containsKey('error')) {
      print('Error: ${result['error']['message']}');
      return 0;
    } else {
      print('Successful RPC call [fetchBalance]');
      final balanceWei = result['result'].toString().substring(2);
      final balanceEth =
          BigInt.parse(balanceWei, radix: 16) / BigInt.from(10).pow(18);
      return balanceEth;
    }
  }
}

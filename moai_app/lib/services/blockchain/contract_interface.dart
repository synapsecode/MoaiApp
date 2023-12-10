import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moai_app/secrets.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class MoaiContractInterface extends ChangeNotifier {
  static const String CONTRACT_ADDRESS =
      '0xbd4b7b4a2fa5571904469a13cad36c2c85bd46ef';
  static const String RPCURL = 'https://sepolia-rpc.scroll.io/';
  static const String CHAINID = '534351';
  static const String BLOCK_EXPLORER_URL = 'https://sepolia.scrollscan.dev';
  static const String TOKENSYMBOL = 'ETH';

  static final instance = MoaiContractInterface();

  bool loading = true;

  Web3Client? _web3client;
  DeployedContract? _deployedContract;
  final EthereumAddress _contractAddress =
      EthereumAddress.fromHex(CONTRACT_ADDRESS);
  String? _abiCode;
  Credentials? _credentials;

  MoaiContractInterface() {
    _initWeb3();
  }

  Future<void> _initWeb3() async {
    // Web3Client initilized
    _web3client = Web3Client(RPCURL, http.Client());
    await _getAbi();
    await _getCredentials();
    await _getDeployedContract();
    notifyListeners();
  }

  Future<List> callContractFuncton(
    ContractFunction func,
    List params,
  ) async {
    if (_deployedContract == null) {
      print('NullContract');
      return [];
    }
    loading = true;
    notifyListeners();
    final res = await _web3client?.call(
      contract: _deployedContract!,
      function: func,
      params: params,
    );
    print('Executed Contract Function: ${func.name}');
    loading = false;
    notifyListeners();
    return res ?? [];
  }

  Future<String> callContractTransaction(
      ContractFunction func, List params) async {
    if (_deployedContract == null) {
      print('NullContract');
      return '';
    }
    if (_credentials == null) {
      print('NullCredentials');
      return '';
    }
    loading = true;
    notifyListeners();
    final res = await _web3client?.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _deployedContract!,
        function: func,
        parameters: params,
      ),
      chainId: int.parse(CHAINID),
    );
    print('Executed Contract Transaction: ${func.name}');
    loading = false;
    notifyListeners();
    return res ?? '';
  }

  payContractFunction(ContractFunction func, double valueInEth) async {
    loading = true;
    notifyListeners();

    final transaction = Transaction(
      to: _deployedContract!.address,
      data: func.encodeCall([]),
      gasPrice: EtherAmount.inWei(
        BigInt.from(5000000000),
      ), // replace with appropriate gas price
      maxGas: 21000, // replace with appropriate gas limit
      value: _valueInWei(valueInEth),
    );
    final response =
        await _web3client!.sendTransaction(_credentials!, transaction);
    print('Transaction hash: ${response}');
    loading = true;
    notifyListeners();
    return response;
  }

  // ================== ExternalFunctions ===============
  /*
    addMember(address _member)
    contribute() payable
    startVoting(address _recipient, uint256 _amount)
    castVote(bool _vote)
    initiateTransfer(address _recipient, uint256 _amount)
    getContractBalance()
  */
  addMember(EthereumAddress address) async {
    final val = await callContractFuncton(
      _deployedContract!.function('addMember'),
      [address],
    );
    print(val);
  }

  initiateVotingProcedure() async {
    final val = await payContractFunction(
      _deployedContract!.function('startVoting'),
      _valueInWei(0.0005),
    );
  }

  contribute(EthereumAddress recipient, double valueInEth) async {
    final val = await callContractFuncton(
      _deployedContract!.function('contribute'),
      [
        recipient,
        _valueInWei(valueInEth),
      ],
    );
    print(val);
  }

  castVote(bool accept) async {
    final val = await callContractFuncton(
      _deployedContract!.function('castVote'),
      [accept],
    );
    print(val);
  }

  initiateTransfer(EthereumAddress recipient, double valueInEth) async {
    final val = await callContractFuncton(
      _deployedContract!.function('initiateTransfer'),
      [
        recipient,
        _valueInWei(valueInEth),
      ],
    );
    print(val);
  }

  getMoaiValue() async {
    final val = await callContractFuncton(
      _deployedContract!.function('getContractBalance'),
      [],
    );
    print(val);
  }

  // =================== Helpers ========================

  _valueInWei(double valueInETH) {
    final txValue = EtherAmount.fromBigInt(
      EtherUnit.wei,
      BigInt.from(valueInETH * pow(10, 18)),
    );
    return txValue;
  }

  Future<void> _getAbi() async {
    // loads json file
    String abiFile =
        await rootBundle.loadString('assets/contracts/MoaiContract.json');

    final abiJSON = jsonDecode(abiFile);
    _abiCode = jsonEncode(abiJSON['abi']);
  }

  Future<void> _getCredentials() async {
    _credentials = EthPrivateKey.fromHex(ETHPRIVATEKEY);
  }

  Future<void> _getDeployedContract() async {
    _deployedContract = DeployedContract(
      ContractAbi.fromJson(_abiCode!, "MoaiContract"),
      _contractAddress,
    );
  }
}

final moaiContractInterface = ChangeNotifierProvider<MoaiContractInterface>(
    (ref) => MoaiContractInterface());

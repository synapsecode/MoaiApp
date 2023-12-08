import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xmtp/xmtp.dart' as xmtp;

class MoaiUserController extends ChangeNotifier {
  xmtp.Client? currentClient;
  xmtp.Signer? currentSigner;

  setCurrentClient(xmtp.Client x) {
    currentClient = x;
    notifyListeners();
  }

  clearcurrentClient() {
    currentClient = null;
    notifyListeners();
  }

  setCurrentSigner(xmtp.Signer x) {
    currentSigner = x;
    notifyListeners();
  }

  clearcurrentSigner() {
    currentSigner = null;
    notifyListeners();
  }
}

final moaiUserController =
    ChangeNotifierProvider<MoaiUserController>((ref) => MoaiUserController());

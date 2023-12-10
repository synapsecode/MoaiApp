import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moai_app/playground/playground_launcher.dart';
import 'package:moai_app/screens/welcome.dart';
import 'package:moai_app/services/xmtp/xmtpinterface.dart';

final navigatorKey = GlobalKey<NavigatorState>();
FlutterSecureStorage get storage => const FlutterSecureStorage();
final gpc = ProviderContainer();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MoaiXMTPInterface.instance.initalizeWalletProvider();
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    UncontrolledProviderScope(
      container: gpc,
      child: const MoaiApplication(),
    ),
  );
}

class MoaiApplication extends StatelessWidget {
  const MoaiApplication({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Moai App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 255, 230, 7)),
          useMaterial3: true,
        ),
        navigatorKey: navigatorKey,
        home: const WelcomeScreen(),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

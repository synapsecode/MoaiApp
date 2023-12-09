import 'package:flutter/material.dart';

extension NavExt on NavigatorState {
  Future<T?> pushNewPage<T>(Widget page) async {
    return push(MaterialPageRoute(builder: (ctx) => page));
  }

  Future<T?> replaceWithNewPage<T>(Widget page) async {
    return pushReplacement(MaterialPageRoute(builder: (ctx) => page));
  }

  pushReplacementAfterPostFrameCallback<T>(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (ctx) => page));
    });
  }

  resetNavigationAfterPostFrameCallback<T>(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => page), (route) => false);
    });
  }
}

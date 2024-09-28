import 'package:flutter/material.dart';
import 'render_local.dart';
import 'render_global.dart';

Scaffold docExamplesPage() {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Doc Examples'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          localCounter(),
          globalCounter(),
        ],
      ),
    ),
  );
}

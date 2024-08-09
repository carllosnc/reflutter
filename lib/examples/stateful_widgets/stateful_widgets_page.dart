import 'package:flutter/material.dart';
import '/react.dart';

Widget counter() {
  var count = 0;

  void increment() {
    count++;
  }

  void decrement() {
    count--;
  }

  return RenderLocal(
    builder: (context, setState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            onPressed: () => setState(increment),
            child: const Text('Increment'),
          ),
          const SizedBox(width: 20),
          Text(count.toString(), style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 20),
          FilledButton(
            onPressed: () => setState(decrement),
            child: const Text('Decrement'),
          ),
        ],
      );
    },
  );
}

Scaffold statefulWidgetPage() {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Stateful Widgets'),
    ),
    body: Center(
      child: counter(),
    ),
  );
}

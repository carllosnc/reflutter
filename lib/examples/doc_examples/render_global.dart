import 'package:flutter/material.dart';
import '../../react.dart';

var counter = globalState(0);

increment() {
  counter.setState((value) => value + 1);
}

Widget incrementButton() {
  return FilledButton(
    onPressed: increment,
    child: Text('Increment ${counter.value}'),
  );
}

Widget globalCounter() {
  return RenderGlobal(
    valueListenable: counter,
    builder: (context, value, child) {
      return incrementButton();
    },
  );
}

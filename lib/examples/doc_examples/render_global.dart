import 'package:flutter/material.dart';
import '../../react.dart';

//global state that can be used in multiple widgets
var counter = globalState(0);

//action that updates the state
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

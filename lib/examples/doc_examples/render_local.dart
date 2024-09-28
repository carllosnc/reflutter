import 'package:flutter/material.dart';
import '../../react.dart';

Widget localCounter() {
  //local variable defined inside the component
  var count = 0;

  //action that updates the state
  void increment() {
    count++;
  }

  return RenderLocal(
    builder: (context, setState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            //call the action to update the state
            //setState will rebuild the widget
            onPressed: () => setState(increment),
            child: Text('Increment: $count'),
          ),
        ],
      );
    },
  );
}

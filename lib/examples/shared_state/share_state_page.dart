// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '/react.dart';

var counter = useState(0);

incrementAction() {
  counter.setState((value) => value + 1);
}

decrementAction() {
  counter.setState((value) => value - 1);
}

Widget incrementCounter() {
  print('Building increment button');

  return const FilledButton(
    onPressed: incrementAction,
    child: Text('Increment'),
  );
}

Widget decrementCounter() {
  print('Building decrement button');

  return const FilledButton(
    onPressed: decrementAction,
    child: Text('Decrement'),
  );
}

Widget displayCounter() {
  return RenderGlobal(
    valueListenable: counter,
    builder: (context, value, child) {
      print('Building display counter');

      return Text(
        counter.value.toString(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      );
    },
  );
}

Widget shareStatePage() {
  counter.useEffect(() {
    print('Counter changed to ${counter.value}');
  });

  return Scaffold(
    appBar: AppBar(
      title: const Text('Shared State'),
    ),
    body: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          incrementCounter(),
          const SizedBox(width: 10),
          displayCounter(),
          const SizedBox(width: 10),
          decrementCounter(),
        ],
      ),
    ),
  );
}

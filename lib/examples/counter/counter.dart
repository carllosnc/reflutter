import 'package:flutter/material.dart';
import '/react.dart';

Widget counter() {
  var count = useState(0);

  increment() {
    count.setState((value) => value + 1);
  }

  decrement() {
    count.setState((value) => value - 1);
  }

  count.useEffect(() {
    debugPrint('count: ${count.value}');
  });

  return Render(
    valueListenable: count,
    builder: (context, value, child) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: increment,
                child: const Text('Increment'),
              ),
              const SizedBox(width: 10),
              Text('$value'),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: decrement,
                child: const Text('Decrement'),
              ),
            ],
          ),
        ],
      );
    },
  );
}
